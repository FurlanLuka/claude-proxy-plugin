# Worked example: one feature in the house style

A server command that redeems a team invite. Three files: the pure rules, the thin service, the
tests. Read it for the rhythm as much as the content.

The service uses Prisma ORM 7 and PostgreSQL, with a unique invite code and a unique
`(teamId, userId)` membership. All operations that change a team's membership or invite
eligibility must lock the same team row before reading those facts, keeping the lock through
commit. Adapt the table names and locking mechanism to the target project's schema and
established concurrency controls. A transaction around writes alone does not protect prior
eligibility reads. See [Prisma transactions](https://www.prisma.io/docs/orm/v7/prisma-client/queries/transactions)
and [PostgreSQL row locks](https://www.postgresql.org/docs/17/explicit-locking.html#LOCKING-ROWS).

## `invite-rules.ts`

```ts
import type { TeamErrorCode } from './team.schema';

/**
 * Who may redeem an invite (TEAMS-0002 §3): a live invite, unused, for someone not already in a
 * team that has room. Pure: the service gathers the facts.
 */

/** An invite lapses after 7 days: the inviter sends a new one. */
export const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000;

export const isInviteLapsed = (createdAt: Date, now: Date): boolean =>
	now.getTime() - createdAt.getTime() > INVITE_TTL_MS;

interface CheckRedeemParams {
	hasInvite: boolean;
	isLapsed: boolean;
	isMember: boolean;
	memberCount: number;
	maxMembers: number;
}

/** Undefined when the invite may be redeemed now. */
export const checkRedeem = ({
	hasInvite,
	isLapsed,
	isMember,
	memberCount,
	maxMembers,
}: CheckRedeemParams): TeamErrorCode | undefined => {
	if (!hasInvite || isLapsed) {
		return 'NO_INVITE';
	}

	// Redeeming twice is a no-op for the caller, not a second seat
	if (isMember) {
		return 'ALREADY_A_MEMBER';
	}

	return memberCount >= maxMembers ? 'TEAM_FULL' : undefined;
};
```

## `redeem-invite.service.ts`

```ts
import { Prisma } from '@prisma/client';
import type {
	RedeemInvitePayload,
	RedeemInviteResponse,
} from './command/redeem-invite.schema';
import { prisma } from '../prisma';
import { checkRedeem, isInviteLapsed } from './invite-rules';
import { MAX_TEAM_MEMBERS, type TeamContext } from './team.service';

/**
 * A team has a fixed seat limit; each invite admits one member once, including concurrent calls.
 */
export const redeemInvite = async (
	{ team, senderId }: TeamContext,
	payload: RedeemInvitePayload,
): Promise<RedeemInviteResponse> => {
	const result = await prisma.$transaction(async (tx): Promise<RedeemInviteResponse> => {
		// Every admission shares this lock: invite reuse and the last seat cannot race
		await tx.$queryRaw`SELECT "id" FROM "Team" WHERE "id" = ${team.id} FOR UPDATE`;
		const [invite, membership, memberCount] = await Promise.all([
			tx.invite.findUnique({ where: { code: payload.code } }),
			tx.member.findUnique({ where: { teamId_userId: { teamId: team.id, userId: senderId } } }),
			tx.member.count({ where: { teamId: team.id } }),
		]);
		const code = checkRedeem({
			hasInvite: invite !== null && invite.teamId === team.id && invite.spentAt === null,
			isLapsed: invite !== null && isInviteLapsed(invite.createdAt, new Date()),
			isMember: membership !== null,
			memberCount,
			maxMembers: MAX_TEAM_MEMBERS,
		});

		if (code) {
			return { type: 'ERROR', code };
		}

		await tx.member.create({ data: { teamId: team.id, userId: senderId } });
		await tx.invite.update({ where: { code: payload.code }, data: { spentAt: new Date() } });

		return { type: 'SUCCESS' };
	}, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted });

	if (result.type === 'ERROR') {
		console.info(`[Teams] Invite ${payload.code} in ${team.id} by ${senderId} refused: ${result.code}`);

		return result;
	}

	console.log(`[Teams] ${senderId} joined ${team.id} with invite ${payload.code}`);

	return result;
};
```

## `invite-rules.test.ts`

```ts
import { describe, expect, it } from 'vitest';
import { checkRedeem, INVITE_TTL_MS, isInviteLapsed } from './invite-rules';

const redeem = (overrides: Partial<Parameters<typeof checkRedeem>[0]> = {}) =>
	checkRedeem({
		hasInvite: true,
		isLapsed: false,
		isMember: false,
		memberCount: 3,
		maxMembers: 10,
		...overrides,
	});

describe('checkRedeem', () => {
	it.each([
		['no invite', { hasInvite: false }, 'NO_INVITE'],
		['a lapsed invite', { isLapsed: true }, 'NO_INVITE'],
		['already a member', { isMember: true }, 'ALREADY_A_MEMBER'],
		['a full team', { memberCount: 10 }, 'TEAM_FULL'],
	] as const)('%s → %s', (_name, overrides, expected) => {
		expect(redeem(overrides)).toBe(expected);
	});

	it('a live invite to a team with room → allowed', () => {
		expect(redeem()).toBeUndefined();
	});
});

describe('isInviteLapsed', () => {
	it('one ms past the TTL → lapsed; exactly at it → still live', () => {
		const createdAt = new Date(1_700_000_000_000);

		expect(isInviteLapsed(createdAt, new Date(createdAt.getTime() + INVITE_TTL_MS + 1))).toBe(true);
		expect(isInviteLapsed(createdAt, new Date(createdAt.getTime() + INVITE_TTL_MS))).toBe(false);
	});
});
```

## What to notice

- The rule takes facts, not a database: it's tested in a table with no mocks.
- The service locks the team, fetches facts, applies the rule and writes in one transaction.
  `ReadCommitted` lets a waiting caller see the previous caller's committed membership and spent
  invite after acquiring the lock. Success is logged only after the transaction commits.
- Declarations run together; each decision gets its own block; a blank line before every
  `return`.
- Comments explain caller-visible constraints and why the lock is necessary.
- The log lines alone tell the story: who, where, what happened, and why it was refused.

## Service regression checks

Run these against a disposable PostgreSQL database using the target project's real service and
schema, with separate connections so the transactions actually contend. Keep the pure rule
tests above; they cannot verify locking or rollback.

- Two users redeem the same live invite concurrently: exactly one succeeds, one receives
  `NO_INVITE`, one membership is created, and the invite is spent once.
- Two users redeem different invites for a team with one remaining seat: exactly one succeeds,
  one receives `TEAM_FULL`, and the losing caller's invite remains unspent.
- The same user redeems concurrently: exactly one membership is created. Retrying a spent
  invite returns `NO_INVITE`; a different live invite returns `ALREADY_A_MEMBER` and stays live.
- A failure while spending the invite rolls back the membership creation and emits no success
  log; a subsequent attempt can still redeem the invite.
