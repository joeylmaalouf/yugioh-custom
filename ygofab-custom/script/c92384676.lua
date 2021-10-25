-- Dark World Vengeance
local s, id = GetID()

function s.initial_effect(c)
	-- card activation effect
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- destruction avoidance effect
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_HANDES + CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_CONTINUOUS + EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.target)
	e2:SetValue(1)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end

s.listed_series = {0x6}

-- check whether a card is a face-up "Dark World" monster you control
function s.filter (c, tp)
	return
		c:IsFaceup()
		and c:IsSetCard(0x6)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsControler(tp)
		and not c:IsReason(REASON_REPLACE)
end

-- if we haven't yet checked for a valid target, we'll confirm that only 1 card is slated for destruction and that it matches our filter
-- if we already have, then whether we have a valid target depends on whether the player wants to use the effect
-- if they do, we'll mark it as such and describe categorically what the effect will involve
-- note: this is all just specifying what card(s) will be affected, it's unrelated to the special "target" keyword
function s.target (e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return
			#eg == 1
			and eg:IsExists(s.filter, 1, nil, tp)
	end
	if Duel.SelectEffectYesNo(tp, e:GetHandler(), 96) then
		Duel.SetTargetCard(eg)
		Duel.SetOperationInfo(0, CATEGORY_TOHAND, eg, 1, 0, 0)
		Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, tp, 1)
		return true
	else
		return false
	end
end

-- here we can actually perform the operation we described earlier
-- we'll get the card we had previously marked as the target and send it to the hand, then have the player discard a card
function s.operation(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	Duel.SendtoHand(tc, tp, REASON_EFFECT)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISCARD)
	Duel.ShuffleHand(tp)
	Duel.DiscardHand(tp, nil, 1, 1, REASON_DISCARD + REASON_EFFECT)
end
