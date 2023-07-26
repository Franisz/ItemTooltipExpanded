require "ISUI/ISToolTipInv"

local ITE = {}

ITE.ISToolTipInv = {}
ITE.ISToolTipInv.render = ISToolTipInv.render
ITE.ISToolTipInv.setY = ISToolTipInv.setY
ITE.ISToolTipInv.setWidth = ISToolTipInv.setWidth
ITE.ISToolTipInv.setHeight = ISToolTipInv.setHeight
ITE.ISToolTipInv.drawRectBorder = ISToolTipInv.drawRectBorder

ITE.swingSpeed = {
  ["Bat"] = 1, 
  ["Heavy"] = 0.6,
  ["Stab"] = 1.13,
  ["Spear"] = 1.13,
}

ITE.Lines = {}
ITE.oldHeight = nil

function ITE.addLine(text)
  table.insert(ITE.Lines, { ["Text"] = text })
end

function ITE.addLine(text, color)
  table.insert(ITE.Lines, { ["Text"] = text, ["Color"] = color })
end

function ITE.getAddedLinesCount()
  local count = 0
  for i = 1, #ITE.Lines do count = count + 1 end
  if count > 0 then count = count + 1 end
  return count
end

function ITE.assignTextWeapon(item, scriptItem)
  if not instanceof(item, "HandWeapon") then
    return
  end

  if item:getSwingAnim() == "Throw" then
    return
  end

  local player = getPlayer() or getSpecificPlayer(0)
  local weaponLevel = 0
  local weaponTypeName = nil
  local category = item:getCategories()

  if item:isRanged() then
    weaponLevel = player:getPerkLevel(Perks.Aiming)
    weaponTypeName = getText("IGUI_perks_Firearm")
  elseif category:contains("Axe") then
    weaponLevel = player:getPerkLevel(Perks.Axe)
    weaponTypeName = getText("IGUI_perks_Axe")
  elseif category:contains("LongBlade") then
    weaponLevel = player:getPerkLevel(Perks.LongBlade)
    weaponTypeName = getText("IGUI_perks_LongBlade")
  elseif category:contains("SmallBlade") then
    weaponLevel = player:getPerkLevel(Perks.SmallBlade)
    weaponTypeName = getText("IGUI_perks_SmallBlade")
  elseif category:contains("SmallBlunt") then
    weaponLevel = player:getPerkLevel(Perks.SmallBlunt)
    weaponTypeName = getText("IGUI_perks_SmallBlunt")
  elseif category:contains("Blunt") then
    weaponLevel = player:getPerkLevel(Perks.Blunt)
    weaponTypeName = getText("IGUI_perks_Blunt")
  elseif category:contains("Spear") then
    weaponLevel = player:getPerkLevel(Perks.Spear)
    weaponTypeName = getText("IGUI_perks_Spear")
  elseif category:contains("Improvised") then
    weaponLevel = 0
    weaponTypeName = getText("Tooltip_ITE_improvised")
  else
    weaponLevel = 0
    weaponTypeName = getText("Tooltip_ITE_unknown")
  end

  if item:isRanged() then
    ITE.addLine(getText("Tooltip_weapon_Type")..": "..weaponTypeName.." ("..ScriptManager.instance:getItem(item:getAmmoType()):getDisplayName()..")")
    ITE.addLine(getText("Tooltip_weapon_Damage")..": "..ITE.round(item:getMinDamage(), 3).." - "..ITE.round(item:getMaxDamage(), 3).." (x1)")
    ITE.addLine(getText("Tooltip_weapon_Range")..": "..ITE.round(item:getMinRangeRanged(), 3).." - "..ITE.round(item:getMaxRange(), 3).." (+"..ITE.round(item:getAimingPerkRangeModifier() * weaponLevel, 3)..")")
    ITE.addLine(getText("Tooltip_ITE_crit")..": "..ITE.round(item:getCriticalChance(), 3).."% (+"..ITE.round(item:getAimingPerkCritModifier() * weaponLevel, 3).."%), "..ITE.round(item:getCritDmgMultiplier(), 3).."x")
    ITE.addLine(getText("Tooltip_ITE_accuracy")..": "..item:getHitChance().."% (+"..ITE.round(item:getAimingPerkHitChanceModifier() * weaponLevel, 3).."%)")
    ITE.addLine(getText("Tooltip_ITE_recoil_aim_reload")..": "..item:getAimingTime().."/"..item:getReloadTime().."/"..item:getRecoilDelay())
    ITE.addLine(getText("Tooltip_ITE_sound_radius")..": "..item:getSoundRadius().." "..getText("Tooltip_ITE_tiles"))
  else
    ITE.addLine(getText("Tooltip_weapon_Type")..": "..weaponTypeName)

    -- Strength
    local bonusDamage = (0.75 + 0.5 * player:getPerkLevel(Perks.Strength))
    -- Weapon level
    bonusDamage = bonusDamage * (0.3 + 0.1 * weaponLevel)
    -- if weaponLevel >= 7 then 
    --   bonusDamage = bonusDamage * 1.2
    -- elseif weaponLevel >= 3 then
    --   bonusDamage = bonusDamage * 1.1
    -- end
    -- Traits
    if player:HasTrait("Strong") then bonusDamage = bonusDamage * 1.4 end
    if player:HasTrait("Weak") then bonusDamage = bonusDamage * 0.6 end
    if player:HasTrait("Underweight") then bonusDamage = bonusDamage * 0.8 end
    if player:HasTrait("VeryUnderweight") then bonusDamage = bonusDamage * 0.6 end
    if player:HasTrait("Emaciated") then bonusDamage = bonusDamage * 0.4 end
    ITE.addLine(getText("Tooltip_weapon_Damage")..": "..ITE.round(item:getMinDamage(), 3).." - "..ITE.round(item:getMaxDamage(), 3).." (x"..ITE.round(bonusDamage, 2)..")")

    local swingAnimSpeed = ITE.swingSpeed[item:getSwingAnim()] or 1
    local speed = item:getBaseSpeed() * swingAnimSpeed
    local bonusSpeed = 0
    if player:HasTrait("axeman") and category:contains("Axe") then
      bonusSpeed = bonusSpeed + 25
    end
    bonusSpeed = bonusSpeed + player:getPerkLevel(Perks.Fitness) * 2 + weaponLevel * 3
    ITE.addLine(getText("Tooltip_ITE_attack_speed")..": "..ITE.round(speed, 3).." (+"..ITE.round(bonusSpeed, 3).."%)")
    local bonusKnockback = -25 + 5 * player:getPerkLevel(Perks.Strength)
    ITE.addLine(getText("Tooltip_ITE_knockback")..": "..ITE.round(item:getPushBackMod(), 3).." (+"..ITE.round(bonusKnockback, 3).."%)")
    ITE.addLine(getText("Tooltip_weapon_Range")..": "..ITE.round(item:getMinRange(), 3).." - "..ITE.round(item:getMaxRange(), 3))
    ITE.addLine(getText("Tooltip_ITE_crit")..": "..ITE.round(item:getCriticalChance(), 3).."% (+"..3 * weaponLevel.."%), x"..ITE.round(item:getCritDmgMultiplier(), 3))
    ITE.addLine(getText("Tooltip_ITE_endurance_used")..": x"..ITE.round(item:getEnduranceMod(), 3))
  end
  
  ITE.addLine(getText("Tooltip_weapon_Condition")..": "..item:getCondition().."/"..item:getConditionMax())
  local bonusConditionLowerChance = math.floor((player:getPerkLevel(Perks.Maintenance) + math.floor(weaponLevel / 2)) / 2) * 2
  ITE.addLine(getText("Tooltip_ITE_break_chance")..": "..getText("Tooltip_ITE_break_chance_one_in").." "..item:getConditionLowerChance().." (+"..bonusConditionLowerChance..")")
end

function ITE.assignTextFood(invItem, scriptItem)
  if not instanceof(invItem, "Food") then 
    return
  end

  if invItem:isSpice() then
    ITE.addLine(getText("Tooltip_ITE_spice"))
  end

  if scriptItem:getDaysTotallyRotten() > 0 and scriptItem:getDaysTotallyRotten() < 1000000000 then
    if invItem:HowRotten() > 1 then
      ITE.addLine(getText("Tooltip_ITE_completely_rotten"), Colors.Red)
    else
      local stateText = nil
      local timeString = nil
      local minutesLeft = 0

      if invItem:HowRotten() > 0 then
        stateText = getText("Tooltip_ITE_rotten")
        minutesLeft = ITE.round((scriptItem:getDaysTotallyRotten() - scriptItem:getDaysFresh()) * 24 * 60 * (1 - invItem:HowRotten()), 0)
      else
        stateText = getText("Tooltip_ITE_stale")
        local staleFactor = scriptItem:getDaysFresh() / (scriptItem:getDaysTotallyRotten() - scriptItem:getDaysFresh()) * -1
        minutesLeft = ITE.round(scriptItem:getDaysFresh() * 24 * 60 * invItem:HowRotten() / staleFactor, 0)
      end

      hoursLeft = ITE.round(minutesLeft / 60, 0)

      if minutesLeft < 60 then
        timeString = minutesLeft..getText("Tooltip_ITE_minute")
      elseif hoursLeft < 24 then
        timeString = hoursLeft..getText("Tooltip_ITE_hour")
      else
        local daysLeft = math.floor(hoursLeft / 24)
        timeString = daysLeft..getText("Tooltip_ITE_day")

        hoursLeft = hoursLeft - daysLeft * 24
        if hoursLeft > 0 then
          timeString = timeString.." "..hoursLeft..getText("Tooltip_ITE_hour")
        end
      end

      ITE.addLine(stateText.." "..getText("Tooltip_ITE_in")..": "..timeString, Colors.DarkOrange)
    end
  end
end

function ITE.assignText(self)
  local invItem = self.item
  local scriptItem = ScriptManager.instance:getItem(invItem:getFullType())
  ITE.assignTextWeapon(invItem, scriptItem)
  ITE.assignTextFood(invItem, scriptItem)
  return #ITE.Lines
end

function ITE.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function ITE.setY(self, y, ...)
  if not self.followMouse and self.anchorBottomLeft then
    local newHeight = self.tooltip:getHeight() + self.tooltip:getLineSpacing() * ITE.getAddedLinesCount()
    y = self.anchorBottomLeft.y - newHeight
  end

  return ITE.ISToolTipInv.setY(self, y, ...)
end

function ITE.setHeight(self, height, ...)
  ITE.oldHeight = height
  local newHeight = height + self.tooltip:getLineSpacing() * ITE.getAddedLinesCount()

  if not self.followMouse and self.anchorBottomLeft then
    self.tooltip:setY(self.anchorBottomLeft.y - newHeight)
  end

  if self.tooltip:getY() + newHeight >= getCore():getScreenHeight() then
    self.tooltip:setY(getCore():getScreenHeight() - newHeight - 1)
  end

  return ITE.ISToolTipInv.setHeight(self, newHeight, ...)
end

function ITE.setWidth(self, width, ...)
  local widestText = 0
  for i = 1, #ITE.Lines do
    widestText = math.max(
      widestText,
      getTextManager():MeasureStringX(UIFont[getCore():getOptionTooltipFont()], ITE.Lines[i]["Text"])
    )
  end

  local spacing = self.tooltip:getLineSpacing()
  local width = math.max(self.tooltip:getWidth(), widestText + spacing / 2) + spacing
  return ITE.ISToolTipInv.setWidth(self, width, ...)
end

function ITE.drawRectBorder(self, ...)
  local startPos = self.tooltip:getHeight() + self.tooltip:getLineSpacing() / 2
  
  for i = 1, #ITE.Lines do
    local position = startPos + self.tooltip:getLineSpacing() * (i - 1)
    local color = ITE.Lines[i]["Color"] or Colors.LemonChiffon
    local text = ITE.Lines[i]["Text"]
    
    -- local name = Colors.GetColorNames():get(ZombRand(1, Colors.GetColorsCount()))
    -- color = Colors.GetColorByName(name)

    self.tooltip:DrawText(text, 5, position, 
    color:getRedFloat(), 
    color:getGreenFloat(), 
    color:getBlueFloat(), 
    color:getAlphaFloat())
  end

  return ITE.ISToolTipInv.drawRectBorder(self, ...)
end

function ISToolTipInv:render()
  if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
    return ITE.ISToolTipInv.render(self)
  end

  if not self.item then
    return ITE.ISToolTipInv.render(self)
  end

  if getActivatedMods():contains("WeaponModifiersFramework") and instanceof(self.item, "HandWeapon") then
    return ITE.ISToolTipInv.render(self)
  end

  if not ITE.assignText(self) then
    return ITE.ISToolTipInv.render(self)
  end

  self.setY = ITE.setY
  self.setWidth = ITE.setWidth
  self.setHeight = ITE.setHeight
  self.drawRectBorder = ITE.drawRectBorder
  ITE.ISToolTipInv.render(self)
  self.setY = ITE.ISToolTipInv.setY
  self.setWidth = ITE.ISToolTipInv.setWidth
  self.setHeight = ITE.ISToolTipInv.setHeight
  self.drawRectBorder = ITE.ISToolTipInv.drawRectBorder

  for k in pairs(ITE.Lines) do
    ITE.Lines[k]["Text"] = nil
    ITE.Lines[k]["Color"] = nil
    ITE.Lines[k] = nil
  end

  -- Reset height to avoid 1 frame flicker
  if ITE.oldHeight ~= nil then
    ITE.ISToolTipInv.setHeight(self, ITE.oldHeight)
    ITE.oldHeight = nil
  end
end

return ITE