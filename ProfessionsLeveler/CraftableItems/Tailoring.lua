local _, T = ...
T[8] = {
    ["Example"] = {
        trainableLevel = 301,
        yellowLevel = 400,
        greyLevel = 500,
		recipe = "Scherecipe: Example Item Vortex", --Recipe name or "None"
		cost = 15000, --Cost in copper or -1 if not purchasable directly
        materials = {"Proton", "Neutron", "Electron"},
        materialsNumber = {92, 143, 92}
    },
}