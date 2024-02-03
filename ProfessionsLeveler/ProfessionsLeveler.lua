-- ProfessionsLeveler.lua

local prof1 = nil
local prof2 = nil
local prof1Skill = nil
local prof2Skill = nil
local cookingSkill = nil

-- Load craftable items for each profession
local _, T = ...
local professionsList = {"Alchemy", "Blacksmithing", "Cooking", "Enchanting", "Engineering", "Leatherworking", "Mining", "Tailoring"}

knownItemPrices = {}
knownItemPrices = T[9]



craftableItemsTable = {}  -- Table to store craftable items for all professions

for i, profession in ipairs(professionsList) do
    craftableItemsTable[profession] = T[i]
end

inputItem = nil
itemNames = {}
itemPrices = {}
requiredItems = {}

AHIndex = 1
scannedItems = {}
scanning = false
currentItem = nil

currentSelectedProf = nil

targetLevel = 75

function round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number)
end

function formatCurrency(amount)
    local isNegative = false
    if amount < 0 then
        isNegative = true
        amount = -amount
    end

    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100

    local result = ""
    
    if isNegative then
        result = "-"
    end

    if gold > 0 then
        result = result .. gold .. "g "
    end

    if silver > 0 or result ~= "" then
        result = result .. silver .. "s "
    end

    if copper > 0 or result == "" then
        result = result .. copper .. "c"
    end

    return result
end

-- Function to get a list of craftable items for a given profession
local function GetCraftableItems(profession)
    -- Check if the profession exists in the table
    if craftableItemsTable[profession] then
        local itemsList = {}
        for itemName, itemInfo in pairs(craftableItemsTable[profession]) do
            local itemString = itemName
            table.insert(itemsList, itemString)
        end

        return itemsList
    else
        return {"No craftable items found for " .. profession}
    end
end

-- Function to calculate the cost to craft an item
local function calculateCost(profN, itemN)
	local totalCost = 0
	local itemMaterials = craftableItemsTable[profN][itemN].materials
	local materialAmounts = craftableItemsTable[profN][itemN].materialsNumber
	for x, material in ipairs(itemMaterials) do
		for y, item in ipairs(requiredItems) do
			if material == item then
				totalCost = totalCost + (itemPrices[y] * materialAmounts[x])
			end
		end
	end
	totalCost = totalCost - craftableItemsTable[profN][itemN].vendor
	return totalCost
end

local function RefreshItemMenu()
    local selectedProfession = currentSelectedProf

    -- Clear existing labels
    itemsFrame:ClearLabels()

    local skillLevel = nil
    if selectedProfession == prof1 then
        skillLevel = prof1Skill
    elseif selectedProfession == prof2 then
        skillLevel = prof2Skill
    elseif selectedProfession == "Cooking" then
        skillLevel = cookingSkill
    end

    -- Update labels for the selected profession
    local craftableItems = GetCraftableItems(selectedProfession)
    itemsFrame.labels = {}
    local yOffset = -35  -- Adjusted Y offset for labels
    local textSet = false
	
	local cItemsList = {}
	local cItemsListPrices = {}
	
    for _, craftableItem in ipairs(craftableItems) do
        local tLevel = craftableItemsTable[selectedProfession][craftableItem].trainableLevel
        local yLevel = craftableItemsTable[selectedProfession][craftableItem].yellowLevel
        local gLevel = craftableItemsTable[selectedProfession][craftableItem].greyLevel
		
		--filters for all items that can give you a skill up between your current skill level and target skill level
        if skillLevel < gLevel and targetLevel > tLevel then
            local skillUpChance = (gLevel - skillLevel) / (gLevel - yLevel)
            if skillUpChance > 1 then
                skillUpChance = 1
            end

            for _, material in ipairs(craftableItemsTable[selectedProfession][craftableItem].materials) do
                local included = false
                for j, k in ipairs(requiredItems) do
                    if material == k then
                        included = true
                    end
                end
                if not included then
                    table.insert(requiredItems, material)
                end
            end

            --awful, literally the worst
            local needPriceData = false
            for zed, _ in ipairs(requiredItems) do
                if itemPrices[zed] == nil then
                    needPriceData = true
                end
            end

            if needPriceData then
                if textSet == false then
                    local label = itemsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    label:SetPoint("TOPLEFT", itemsFrame, 20, yOffset)
                    label:SetText("Need Item Price Data")
                    itemsFrame.labels[craftableItem] = label
                    yOffset = yOffset - 15  -- Adjusted Y offset between labels
                    textSet = true
                end
            else
                local effectiveCost = calculateCost(selectedProfession, craftableItem) / skillUpChance 
				table.insert(cItemsList, craftableItem)
				table.insert(cItemsListPrices, effectiveCost)
            end
        end
    end
	
	local sortTable = {}
	for i = 1, #cItemsList do
		table.insert(sortTable, {name = cItemsList[i], price = cItemsListPrices[i]})
	end
	
	local function compareItems(item1, item2)
		return item1.price < item2.price
	end
	
	table.sort(sortTable, compareItems)
	
	for _, item in ipairs(sortTable) do
		
	
		local label = itemsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", itemsFrame, 20, yOffset)
        label:SetText(item.name)  -- Set label text
        itemsFrame.labels[item.name] = label
		
		local label = itemsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPRIGHT", itemsFrame, -20, yOffset)
        label:SetText(formatCurrency(item.price))  -- Set label text
        itemsFrame.labels[item.price] = label
		
        yOffset = yOffset - 15  -- Adjusted Y offset between labels
	end

    for v, item in ipairs(requiredItems) do
        itemNames[v] = requiredItems[v]
    end

    -- Ensure that itemsFrame is shown when switching professions
    itemsFrame:Show()
    frame:Hide()
end

-- Function to check trained professions including First Aid and Cooking
local function GetTrainedProfessions()
    local professions = {}
	
    for i = 1, GetNumSkillLines() do
        local skillName, _, _, skillLevel, _, _, _, isTradeSkill = GetSkillLineInfo(i)
        if isTradeSkill or skillName == "Cooking" then
			if skillName ~= "Herbalism" and skillName ~= "Skinning" then
				if prof1 == nil and skillName ~= "Cooking" and skillName ~= "First Aid" then
					prof1 = skillName
					prof1Skill = skillLevel
				elseif prof2 == nil and skillName ~= "Cooking" and skillName ~= "First Aid"  then
					prof2 = skillName
					prof2Skill = skillLevel
				end
				if skillName == "Cooking" then
					cookingSkill = skillLevel
				end
				table.insert(professions, skillName)
			end
        end
    end
    
    return professions
end

local function QueryNextItem()
    if AHIndex <= #requiredItems then
        local itemName = requiredItems[AHIndex]
		currentItem = itemName
		if not scannedItems[itemName] then
			QueryAuctionItems(itemName)
			scannedItems[itemName] = true
		else
			AHIndex = AHIndex + 1
			QueryNextItem()
		end
	else
		if scanning == true then
			print("Scan Finished")
			RefreshItemMenu()
		end
		scanning = false
    end
	
	local percentage = math.floor((AHIndex / #requiredItems) * 100)
    local progressLabel = itemsFrame.progressLabel or itemsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressLabel:SetPoint("BOTTOMLEFT", itemsFrame, 35, 35)
    progressLabel:SetText(percentage .. "%")
    itemsFrame.progressLabel = progressLabel
	if scanning == false then
		progressLabel:SetText("")
	end
	
end

local function OnAuctionUpdate()
    if CanSendAuctionQuery() then
        QueryNextItem()
    else
        -- Wait for a short period and try again
        C_Timer.After(0.3, OnAuctionUpdate)  -- Adjust the delay as needed
    end
end

-- Function to create a frame for inputting gold, silver, and copper
local function CreateInputFrame(acceptFunc)
    local inputFrame = CreateFrame("Frame", "ProfessionsLevelerInputFrame", UIParent, "UIPanelDialogTemplate")
    inputFrame:SetSize(164, 90)
    inputFrame:SetPoint("CENTER")
    inputFrame:SetMovable(true)
    inputFrame:EnableMouse(true)
    inputFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
    inputFrame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
    end)

    -- Create edit boxes for gold, silver, and copper
    inputFrame.goldEditBox = CreateFrame("EditBox", "ProfessionsLevelerGoldEditBox", inputFrame, "InputBoxTemplate")
    inputFrame.goldEditBox:SetSize(30, 20)
    inputFrame.goldEditBox:SetPoint("TOPLEFT", inputFrame, 20, -32)
    inputFrame.goldEditBox:SetAutoFocus(false)
    inputFrame.goldEditBox:SetNumeric(true)
    inputFrame.goldEditBox:SetTextInsets(5, 0, 0, 0)

    inputFrame.silverEditBox = CreateFrame("EditBox", "ProfessionsLevelerSilverEditBox", inputFrame, "InputBoxTemplate")
    inputFrame.silverEditBox:SetSize(30, 20)
    inputFrame.silverEditBox:SetPoint("TOPLEFT", inputFrame.goldEditBox, "TOPRIGHT", 10, 0)
    inputFrame.silverEditBox:SetAutoFocus(false)
    inputFrame.silverEditBox:SetNumeric(true)
    inputFrame.silverEditBox:SetTextInsets(5, 0, 0, 0)

    inputFrame.copperEditBox = CreateFrame("EditBox", "ProfessionsLevelerCopperEditBox", inputFrame, "InputBoxTemplate")
    inputFrame.copperEditBox:SetSize(30, 20)
    inputFrame.copperEditBox:SetPoint("TOPLEFT", inputFrame.silverEditBox, "TOPRIGHT", 10, 0)
    inputFrame.copperEditBox:SetAutoFocus(false)
    inputFrame.copperEditBox:SetNumeric(true)
    inputFrame.copperEditBox:SetTextInsets(5, 0, 0, 0)
	
	
	inputFrame.title = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	inputFrame.title:SetPoint("TOP", inputFrame, 0, -10)  -- Adjusted Y position
	
	-- Clear Function
	inputFrame.clearBoxes = function()
		inputFrame.title:SetText("")
		inputFrame.goldEditBox:SetText("")
        inputFrame.silverEditBox:SetText("")
        inputFrame.copperEditBox:SetText("")
	end
	
	-- Function to set title
    inputFrame.setTitle = function(titleText)
		inputFrame.title:SetText(titleText)
    end
	
    inputFrame.skipButton = CreateFrame("Button", "ProfessionsLevelerAcceptButton", inputFrame, "UIPanelButtonTemplate")
    inputFrame.skipButton:SetSize(70, 22)
    inputFrame.skipButton:SetPoint("BOTTOM", inputFrame, 35, 10)
    inputFrame.skipButton:SetText("Skip")
	
	-- Function to handle skip button click
    inputFrame.skipButton:SetScript("OnClick", function(self)
		local gold = 0
        local silver = 0
        local copper = 0
        acceptFunc(gold, silver, copper)
        inputFrame:Hide()
    end)
	
    -- Add an "Accept" button
    inputFrame.acceptButton = CreateFrame("Button", "ProfessionsLevelerAcceptButton", inputFrame, "UIPanelButtonTemplate")
    inputFrame.acceptButton:SetSize(70, 22)
    inputFrame.acceptButton:SetPoint("BOTTOM", inputFrame, -35, 10)
    inputFrame.acceptButton:SetText("Accept")
    inputFrame.acceptButton:SetScript("OnClick", function(self)
        local gold = tonumber(inputFrame.goldEditBox:GetText()) or 0
        local silver = tonumber(inputFrame.silverEditBox:GetText()) or 0
        local copper = tonumber(inputFrame.copperEditBox:GetText()) or 0

        if acceptFunc then
            acceptFunc(gold, silver, copper)
        end

        inputFrame:Hide()
    end)

    return inputFrame
end

-- Usage example
local function InputCallback(gold, silver, copper)
	if copper == nil then
		copper = 0
	end
	if silver == nil then
		silver = 0
	end
	if gold == nil then
		gold = 0
	end

	if silver > 99 then
		print("Silver cost of " .. silver .. " is too high.")
		silver = 0
	end
	if copper > 99 then
		print("Copper cost of " .. copper .. " is too high.")
		copper = 0
	end
	gold = gold * 10000
	silver = silver * 100
	local cost = gold+silver+copper
	for p, item in ipairs(requiredItems) do
		if inputItem == requiredItems[p] then
			itemPrices[p] = cost
		end
	end
end

-- Function to create a frame for displaying craftable items
local function CreateCraftableItemsFrame()
    local itemsFrame = CreateFrame("Frame", "ProfessionsLevelerItemsFrame", UIParent, "UIPanelDialogTemplate")
    itemsFrame:SetSize(300, 450)
    itemsFrame:SetPoint("CENTER")
    itemsFrame:SetMovable(true)
    itemsFrame:EnableMouse(true)
    itemsFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
    itemsFrame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
    end)
    itemsFrame:Hide()  -- Hide the frame initially

    -- Add a title to the frame
    itemsFrame.title = itemsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsFrame.title:SetPoint("TOP", itemsFrame, 0, -10)  -- Adjusted Y position
    itemsFrame.title:SetText("Craftable Items")
    
    -- Add a back button
    itemsFrame.backButton = CreateFrame("Button", "ProfessionsLevelerBackButton", itemsFrame, "UIPanelButtonTemplate")
    itemsFrame.backButton:SetSize(80, 22)  -- Set button size
    itemsFrame.backButton:SetPoint("BOTTOM", itemsFrame, 100, 12)  -- Adjusted Y position
    itemsFrame.backButton:SetText("Back")
	
	-- Add a scan button
    itemsFrame.scanButton = CreateFrame("Button", "ProfessionsLevelerScanButton", itemsFrame, "UIPanelButtonTemplate")
    itemsFrame.scanButton:SetSize(80, 22)  -- Set button size
    itemsFrame.scanButton:SetPoint("BOTTOM", itemsFrame, -100, 12)  -- Adjusted Y position
    itemsFrame.scanButton:SetText("Scan")
	
	-- Add a reset button
    itemsFrame.resetButton = CreateFrame("Button", "ProfessionsLevelerScanButton", itemsFrame, "UIPanelButtonTemplate")
    itemsFrame.resetButton:SetSize(80, 22)  -- Set button size
    itemsFrame.resetButton:SetPoint("BOTTOM", itemsFrame, 0, 12)  -- Adjusted Y position
    itemsFrame.resetButton:SetText("Reset")

    -- Function to handle back button click
    itemsFrame.backButton:SetScript("OnClick", function(self)
		currentSelectedProf = nil
        itemsFrame:Hide()
        frame:Show()
    end)

    -- Function to handle scan button click
    itemsFrame.scanButton:SetScript("OnClick", function(self)
		--for sd, fd in ipairs(requiredItems) do
		--	print(requiredItems[sd])
		--end
		
		for lolk, itemX in ipairs(requiredItems) do
			for itemNameSD, itemDataSD in pairs(knownItemPrices) do
				if itemNameSD == itemX then
					itemPrices[lolk] = itemDataSD.price
					scannedItems[itemNameSD] = true
				end
			end
		end
		
		print("Scan Started")
		scanning = true
		QueryNextItem()
		
		-- Old code for manual price input
		--for i, item in ipairs(requiredItems) do
		--	if itemPrices[i] == nil then
		--		itemsFrame.inputFrame.clearBoxes()
		--		itemsFrame.inputFrame.setTitle(item)
		--		itemsFrame.inputFrame:Show()
		--		inputItem = item
		--		break
		--	end
		--end
    end)
	
    -- Function to handle reset button click
    itemsFrame.resetButton:SetScript("OnClick", function(self)
		AHIndex = 1
        itemPrices = {}
		scannedItems = {}
		if itemPrices == {} then
			requiredItems = {}
		end
		RefreshItemMenu()
    end)
	
	-- Function to clear labels
    itemsFrame.ClearLabels = function()
        if itemsFrame.labels then
            for _, label in pairs(itemsFrame.labels) do
                label:SetText("")
                label:Hide()
            end
            itemsFrame.labels = {}
        end
    end	

    return itemsFrame
end

-- Runs on player entering world event
local function OnPlayerLogin()
	
	-- Create buttons for trained professions
	local trainedProfessions = GetTrainedProfessions()
	frame.buttons = {}
	local yOffset = -32  -- Adjusted Y offset for buttons

	for _, profession in ipairs(trainedProfessions) do
		local button = CreateFrame("Button", "ProfessionsLeveler_" .. profession:gsub(" ", "") .. "Button", frame, "UIPanelButtonTemplate")
		button:SetSize(150, 30)  -- Set button size
		button:SetPoint("TOPLEFT", frame, 15, yOffset)
		button:SetText(profession)  -- Set button text
		frame.buttons[profession] = button
		yOffset = yOffset - 32
	end
	
	-- Set up event handler for profession button clicks
	for _, button in pairs(frame.buttons) do
		button:SetScript("OnClick", function(self)
			local selectedProfession = self:GetText()
			currentSelectedProf = selectedProfession
	
			-- Update the title and labels for the selected profession
			itemsFrame.title:SetText(selectedProfession .. " Craftable Items")
			
			-- Clear existing labels
			itemsFrame:ClearLabels()
			
			RefreshItemMenu()
		end)
	end
end

-- Create a frame
frame = CreateFrame("Frame", "ProfessionsLevelerFrame", UIParent, "UIPanelDialogTemplate")
frame:SetSize(180, 142)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)
frame:SetScript("OnMouseUp", function(self, button)
    self:StopMovingOrSizing()
end)
frame:Hide()  -- Hide the frame initially

-- Add a title to the frame
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("TOP", frame, 0, -10)  -- Adjusted Y position
frame.title:SetText("Select a Profession")

-- Slash Commands to show the menu
SLASH_PROFESSIONSLEVELER1 = "/professionsleveler"
SLASH_PROFESSIONSLEVELER2 = "/pl"

function SlashCmdList.PROFESSIONSLEVELER()
    frame:Show()
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        OnPlayerLogin()
    end
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "AUCTION_ITEM_LIST_UPDATE" then
		if scanning == true then
			local lowestPrice = math.huge
			local buyoutPrice
			local count
			local name = currentItem
		
			for i = 1, GetNumAuctionItems("list") do
				_, _, count, _, _, _, _, _, _, buyoutPrice = GetAuctionItemInfo("list", i)
				local realPrice = buyoutPrice / count
				if buyoutPrice and realPrice < lowestPrice then
					lowestPrice = realPrice
				end
			end
		
			if name then
				for op, jkl in ipairs(requiredItems) do
					if jkl == name then
						if lowestPrice == math.huge then
							lowestPrice = 1000000
						end
						itemPrices[op] = round(lowestPrice, 0)
					end
				end
			end
		
			-- After processing, trigger the next query
			OnAuctionUpdate()
		end

    end
end)

itemsFrame = CreateCraftableItemsFrame()
itemsFrame.inputFrame = CreateInputFrame(InputCallback)
itemsFrame.inputFrame:Hide()
