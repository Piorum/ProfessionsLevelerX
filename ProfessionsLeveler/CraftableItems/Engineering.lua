local _, T = ...
T[5] = {
    ["Example"] = {
        trainableLevel = 301,
        yellowLevel = 400,
        greyLevel = 500,
		recipe = "Scherecipe: Example Item Vortex", --Recipe name or "None"
		cost = 15000, --Cost in copper or -1 if not purchasable directly
        materials = {"Proton", "Neutron", "Electron"},
        materialsNumber = {92, 143, 92}
    },
    ["Atomic Bomb"] = {
        trainableLevel = 325,
        yellowLevel = 345,
        greyLevel = 400,
		recipe = "None",
		cost = 0,
        materials = {"Example", "Aluminum Bars", "Global Thermal Sapper Charge"},
        materialsNumber = {1, 18, 5}
    },
    ["Gnomish Goggles"] = {
        trainableLevel = 150,
        yellowLevel = 160,
        greyLevel = 180,
		recipe = "None",
		cost = 1500, --Cost in Copper
        materials = {"Bronze Bar", "Glass Eye", "Flask of Oil"},
        materialsNumber = {5, 2, 3}
    },
    ["Mechanical Squirrel"] = {
        trainableLevel = 160,
        yellowLevel = 170,
        greyLevel = 190,
		recipe = "Schematic: Mechanical Squirrel",
		cost = -1, --Flag for no purchasable recipe, will need auction house
        materials = {"Copper Bar", "Linen Cloth", "Whirring Bronze Gizmo"},
        materialsNumber = {10, 5, 3}
    },
}