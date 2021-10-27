-- Vylett, Underlord of Dark World
local s, id = GetID()

function s.initial_effect (c)
	-- must be properly summoned before reviving
	c:EnableReviveLimit()
	-- needs exactly 2 "Dark World" materials
	Link.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsSetCard, 0x6), 2, 2)

	-- effect 1: on summon, draw then discard or banish
	local e1 = Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW + CATEGORY_HANDES + CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_TRIGGER_F + EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.draw_condition)
	e1:SetTarget(s.draw_target)
	e1:SetOperation(s.draw_operation)
	c:RegisterEffect(e1)

	-- effect 2: on attack, retrieve
	local e2 = Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_TRIGGER_O + EFFECT_TYPE_SINGLE)
	e2:SetCode(EVENT_BATTLED)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.retrieve_condition)
	e2:SetTarget(s.retrieve_target)
	e2:SetOperation(s.retrieve_operation)
	c:RegisterEffect(e2)

	-- effect 3: on pointed-to attack, discard
	local e3 = Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_HANDES)
	e3:SetType(EFFECT_TYPE_TRIGGER_O + EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_BATTLED)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.discard_condition)
	e3:SetTarget(s.discard_target)
	e3:SetOperation(s.discard_operation)
	c:RegisterEffect(e3)
end

s.listed_series = {0x6}
s.listed_names = {id}

-- the event triggers on any successful special summon, so we have to add another condition to make sure it's a link summon
function s.draw_condition (e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- if we haven't yet checked for a valid target, we'll confirm that the player can draw 2 cards
-- if we already have, then we'll mark that as the current operation
-- we won't SetOperationInfo for discard or banish here, since we don't know yet which path they'll take
function s.draw_target (e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsPlayerCanDraw(tp, 2)
	end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 2)
end

-- we'll be using this "Dark World" monster check multiple times
function s.base_filter (c)
	return c:IsSetCard(0x6) and c:IsType(TYPE_MONSTER)
end

-- the on-summon effect needs a "Dark World" monster that can be discarded
function s.discard_filter (c)
	return s.base_filter(c) and c:IsDiscardable()
end

-- we'll get the player and card amount we had previously noted, and have that player draw that many cards
-- then they have to discard a valid target, or we banish their entire hand if they can't
function s.draw_operation (e, tp, eg, ep, ev, re, r, rp)
	local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	Duel.Draw(p, d, REASON_EFFECT)
	Duel.ShuffleHand(p)
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
	local g = Duel.SelectMatchingCard(p, s.discard_filter, p, LOCATION_HAND, 0, 1, 1, nil)
	local tg = g:GetFirst()
	if tg then
		Duel.SendtoGrave(tg, REASON_DISCARD + REASON_EFFECT)
	else
		local sg = Duel.GetFieldGroup(p, LOCATION_HAND, 0)
		Duel.Remove(sg, POS_FACEUP, REASON_EFFECT)
	end
end

-- we have to set up a condition for the on attack effect to ensure that this card is the one instigating the battle
function s.retrieve_condition (e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetAttacker() == e:GetHandler()
end

-- the on-attack effect needs a "Dark World" monster that can be sent to hand
function s.retrieve_filter (c)
	return s.base_filter(c) and c:IsAbleToHand()
end

-- if any valid targets are available, we'll have the player choose one
function s.retrieve_target (e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingTarget(s.retrieve_filter, tp, LOCATION_GRAVE, 0, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectTarget(tp, s.retrieve_filter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
end

-- once the effect can actually go through, we can add the target to the player's hand
-- (unless another card further up the chain has gotten involved and claimed that target for itself, leaving us with nothing)
function s.retrieve_operation (e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetChainInfo(0, CHAININFO_TARGET_CARDS)
	local sg = g:Filter(Card.IsRelateToEffect, nil, e)
	if #sg > 0 then
		Duel.SendtoHand(sg, nil, REASON_EFFECT)
		Duel.ConfirmCards(1 - tp, sg)
		Duel.ShuffleHand(tp)
	end
end

-- we have to set up a condition for the on pointed-to attack effect to actually check whether the attacker is pointed to
function s.discard_condition (e, tp, eg, ep, ev, re, r, rp)
	local a = Duel.GetAttacker()
	return a and s.base_filter(a) and a:IsControler(e:GetHandlerPlayer()) and e:GetHandler():GetLinkedGroup():IsContains(a)
end

-- to discard on a pointed-to-monster's attack, we first need to ensure that we have a nonzero number of cards in hand
function s.discard_target (e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0) > 0
	end
	Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, tp, 1)
end

-- if the effect goes through, we can ask the player which card they want to discard
function s.discard_operation (e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
	Duel.DiscardHand(tp, nil, 1, 1, REASON_DISCARD + REASON_EFFECT)
end
