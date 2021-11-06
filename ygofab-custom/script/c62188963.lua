-- Vampire's Battlefield
local s, id = GetID()

function s.initial_effect (c)
	-- effect 1: card activation
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- effect 2: gain lp on kill
	local e2 = Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_TRIGGER_F + EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCondition(s.kill_recover_condition)
	e2:SetTarget(s.kill_recover_target)
	e2:SetOperation(s.recover_operation)
	c:RegisterEffect(e2)

	-- effect 3: gain lp on death
	local e3 = Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_TRIGGER_F + EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EVENT_BATTLE_DESTROYED)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCondition(s.death_recover_condition)
	e3:SetTarget(s.death_recover_target)
	e3:SetOperation(s.recover_operation)
	c:RegisterEffect(e3)
end

s.listed_series = {0x8e}

-- check whether one of your face-up "Vampire" monsters just destroyed an opponent's monster by battle
function s.kill_recover_condition (e, tp, eg, ep, ev, re, r, rp)
	local tc = eg:GetFirst()
	return
		tc:IsControler(tp)
		and tc:IsFaceup()
		and tc:IsSetCard(0x8e)
		and tc:IsRelateToBattle()
		and tc:IsStatus(STATUS_OPPO_BATTLE)
end

-- if the destroyed monster has a level or rank, we'll calculate the heal amount based on that
-- we aren't checking rating, so the heal amount could be 0; in those cases, there's no need to go through with the operation
function s.recover_target (tp, tc, mult, chk)
	local level = 0
	if tc:IsType(TYPE_XYZ) then
		level = tc:GetRank()
	else
		level = tc:GetLevel()
	end
	local amount = level * mult
	if chk == 0 then
		return amount > 0
	end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(amount)
	Duel.SetOperationInfo(0, CATEGORY_RECOVER, nil, 0, tp, amount)
end

-- on kill, the target is the opponent's monster and the multiplier is higher
function s.kill_recover_target (e, tp, eg, ep, ev, re, r, rp, chk)
	local tc = eg:GetFirst():GetBattleTarget()
	return s.recover_target(tp, tc, 500, chk)
end

-- recover the calculated amount of life points
function s.recover_operation (e, tp, eg, ep, ev, re, r, rp)
	local p, a = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	Duel.Recover(p, a, REASON_EFFECT)
end

-- check whether one of your "Vampire" monsters was destroyed by battle with an enemy monster
function s.death_recover_filter (c, tp)
	local rc = c:GetReasonCard()
	return
		c:GetPreviousControler() == tp
		and c:IsSetCard(0x8e)
		and c:IsReason(REASON_BATTLE)
		and rc
		and rc:IsControler(1 - tp)
		and rc:IsRelateToBattle()
end

-- if any cards in the event group match our filter, we can continue onwards
function s.death_recover_condition (e, tp, eg, ep, ev, re, r, rp)
	return eg:FilterCount(s.death_recover_filter, nil, tp) > 0
end

-- on death, the target is your monster and the multiplier is lower
function s.death_recover_target (e, tp, eg, ep, ev, re, r, rp, chk)
	local tc = eg:GetFirst()
	return s.recover_target(tp, tc, 200, chk)
end
