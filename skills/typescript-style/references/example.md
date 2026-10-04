# Worked example: one feature in the house style

A server command that redeems a team invite. Three files: the pure rules, the thin service, the
tests. Read it for the rhythm as much as the content.

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
import type {
	RedeemInvitePayload,
	RedeemInviteResponse,
} from './command/redeem-invite.schema';
import { prisma } from '../prisma';
import { checkRedeem, isInviteLapsed } from './invite-rules';
import { MAX_TEAM_MEMBERS, type TeamContext } from './team.service';

/**
 * Redeems an invite: the member is added and the invite is spent in one step, so a retry can
 * never add a second seat.
 */
export const redeemInvite = async (
	{ team, senderId }: TeamContext,
	payload: RedeemInvitePayload,
): Promise<RedeemInviteResponse> => {
	const [invite, membership, memberCount] = await Promise.all([
		prisma.invite.findUnique({ where: { code: payload.code } }),
		prisma.member.findUnique({ where: { teamId_userId: { teamId: team.id, userId: senderId } } }),
		prisma.member.count({ where: { teamId: team.id } }),
	]);
	const code = checkRedeem({
		hasInvite: invite !== null && invite.teamId === team.id && invite.spentAt === null,
		isLapsed: invite !== null && isInviteLapsed(invite.createdAt, new Date()),
		isMember: membership !== null,
		memberCount,
		maxMembers: MAX_TEAM_MEMBERS,
	});

	if (code) {
		console.info(`[Teams] Invite ${payload.code} in ${team.id} by ${senderId} refused: ${code}`);

		return { type: 'ERROR', code };
	}

	await prisma.$transaction([
		prisma.member.create({ data: { teamId: team.id, userId: senderId } }),
		prisma.invite.update({ where: { code: payload.code }, data: { spentAt: new Date() } }),
	]);
	console.log(`[Teams] ${senderId} joined ${team.id} with invite ${payload.code}`);

	return { type: 'SUCCESS' };
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
- The service reads top to bottom: fetch, rule, refuse with a log, one transaction, log, return.
- Declarations run together; each decision gets its own block; a blank line before every
  `return`.
- Every comment is a reason ("so a retry can never add a second seat"), not a narration.
- The log lines alone tell the story: who, where, what happened, and why it was refused.
