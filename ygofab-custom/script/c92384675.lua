-- Vylett, Underlord of Dark World
local s, id = GetID()

function s.initial_effect (c)
	-- must be properly summoned before reviving
	c:EnableReviveLimit()
	-- needs exactly 2 "Dark World" materials
	Link.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsSetCard, 0x6), 2, 2)

	-- effect 1: draw then discard or banish
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW + CATEGORY_HANDES + CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_TRIGGER_F + EFFECT_TYPE_SINGLE)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- effect 2: retrieve monster on attack
	-- TODO

	-- effect 3: discard on pointed-to attack
	-- TODO
end

s.listed_series = {0x6}

-- the event triggers on any successful special summon, so we have to add another condition to make sure it's a link summon
function s.condition (e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- if we haven't yet checked for a valid target, we'll confirm that the player can draw 2 cards
-- if we already have, then we'll mark that as the current operation
-- we won't SetOperationInfo for discard or banish here, since we don't know yet which path they'll take
function s.target (e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsPlayerCanDraw(tp, 2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 2)
end

-- we only let them discard a "Dark World" monster for the on-summon effect
function s.filter (c)
	return c:IsSetCard(0x6) and c:IsType(TYPE_MONSTER) and c:IsDiscardable()
end

-- we'll get the player and card amount we had previously noted, and have that player draw that many cards
-- then they have to discard a valid target, or we banish their entire hand if they can't
function s.operation (e, tp, eg, ep, ev, re, r, rp)
	local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	Duel.Draw(p, d, REASON_EFFECT)
	Duel.ShuffleHand(p)
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
	local g = Duel.SelectMatchingCard(p, s.filter, p, LOCATION_HAND, 0, 1, 1, nil)
	local tg = g:GetFirst()
	if tg then
		Duel.SendtoGrave(tg, REASON_DISCARD + REASON_EFFECT)
	else
		local sg = Duel.GetFieldGroup(p, LOCATION_HAND, 0)
		Duel.Remove(sg, POS_FACEUP, REASON_EFFECT)
	end
end
