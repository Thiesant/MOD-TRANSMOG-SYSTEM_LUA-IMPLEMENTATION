local ADDON_NAME, Transmog = ...

-- French Localization
Transmog.L = Transmog.L or {}
local L = Transmog.L

-- Only override if client is French
if GetLocale() ~= "frFR" then return end

-- UI Strings
L["ADDON_TITLE"] = "Transmogrification"
L["INSTRUCTIONS"] = "|cff00ff00Clic Gauche:|r rotation  |  |cff00ff00Clic Droit:|r déplacer  |  |cff00ff00Molette:|r zoom"
L["RESET"] = "Réinit."
L["UNDRESS"] = "Déshabiller"
L["PAGE"] = "Page %d/%d"
L["TAB_NAME"] = "Transmogrification"
L["APPLY"] = "Appliquer"
L["APPLY_APPEARANCE_SHIFT_CLICK"] = "|cff00ff00Shift+Clic:|r Appliquer l'apparence"
L["PREVIEW_APPEARANCE_CLICK"] = "|cff00ff00Clic:|r Aperçu"
L["MINIMAP_BUTTON_TITLE"] = "Transmo Collection"

-- Collection Status
L["ACTIVE_TRANSMOG"] = "Transmogrification utilisée:"
L["NO_ACTIVE_TRANSMOG"] = "Aucune transmogrification"
L["TRANSMOG_SLOT_ACTIVE"] = "|cff00ff00ACTIVE|r"
L["CLEAR_TRANSMOG"]= "|cffff0000Clic droit pour retirer|r"
L["APPEARANCE_COLLECTED"] = "|cff00ff00Apparence collectée|r"
L["APPEARANCE_NOT_COLLECTED"] = "|cffff0000Apparence non collectée|r"
L["NEW_APPEARANCE"] = "|cffFFD700NOUVELLE APPARENCE!|r"
L["NEW_APPEARANCE_UNLOCKED"] = "Nouvelle apparence débloquée:"
L["RETROACTIVE_UNLOCKED"] = "%d apparences débloquées depuis les quêtes terminées."
L["TRANSMOG_APPLIED"] = "Transmogrification appliquée!"
L["TRANSMOG_REMOVED"] = "Transmogrification retirée!"

-- Slot Names
L["Head"] = "Tête"
L["Shoulder"] = "Épaule"
L["Back"] = "Dos"
L["Chest"] = "Torse"
L["Shirt"] = "Chemise"
L["Tabard"] = "Tabard"
L["Wrist"] = "Poignets"
L["Hands"] = "Mains"
L["Waist"] = "Taille"
L["Legs"] = "Jambes"
L["Feet"] = "Pieds"
L["MainHand"] = "Main droite"
L["SecondaryHand"] = "Main gauche"
L["Ranged"] = "À distance"

-- Armor Types
L["All"] = "Tous"
L["Cloth"] = "Tissu"
L["Leather"] = "Cuir"
L["Mail"] = "Mailles"
L["Plate"] = "Plaques"
L["Miscellaneous"] = "Divers"

-- Weapon Types
L["Axe1H"] = "Hache à une main"
L["Mace1H"] = "Masse à une main"
L["Sword1H"] = "Épée à une main"
L["Dagger"] = "Dague"
L["Fist"] = "Arme de pugilat"
L["Axe2H"] = "Hache à deux mains"
L["Mace2H"] = "Masse à deux mains"
L["Sword2H"] = "Épée à deux mains"
L["Polearm"] = "Arme d'hast"
L["Staff"] = "Bâton"
L["Shield"] = "Bouclier"
L["Held"] = "Tenu en main gauche"
L["Bow"] = "Arc"
L["Crossbow"] = "Arbalète"
L["Gun"] = "Arme à feu"
L["Wand"] = "Baguette"
L["Thrown"] = "Arme de jet"
L["Fishing"] = "Canne à pêche"

-- Search
L["SEARCH"] = "Rechercher"
L["SEARCH_TOOLTIP"] = "Options de recherche:"
L["SEARCH_CLEAR"] = "Supprimer"
L["SEARCH_NAME"] = "Nom"
L["SEARCH_NAME_DESCRIPTION"] = ": Entrer le nom d'un objet (anglais ou français)"
L["SEARCH_ID"] = "ID"
L["SEARCH_ID_DESCRIPTION"] = ": Entrer l'ID de l'objet"
L["SEARCH_DISPLAYID"] = "DisplayID"
L["SEARCH_DISPLAYID_DESCRIPTION"] = ": Entrer le display ID"
L["SEARCH_TOOLTIP"] = "Recherche par nom, ID, ou display ID"
L["SEARCH_RESULTS"] = "Résultats: %d objets"
L["SEARCH_DESCRIPTION"] = "Taper entrer pour rechercher"
L["SEARCH_CLEAR"] = "Vider le champs"
L["SEARCH_CLEAR_DESCRIPTION"] = "Taper échappe pour vider le champs"


-- Messages
L["COLLECTION_LOADED"] = "Collection chargée: %d apparences"
L["SLASH_TRANSMOG"] = "Addon |cff00ff00[Transmog]|r chargé. Tapper /transmog ou /tmog pour l'ouvrir."
L["HELP_1"] = "|cff00ff00[Transmog]|r Aide:"
L["HELP_2"] = "  /transmog - Ouvre/ferme la fenêtre de transmogrification"
L["HELP_3"] = "  /transmog help - Montre ce message d'aide"
--L["HELP_4"] = ""

-- Error Messages
L["APPEARANCE_NOT_COLLECTED"] = "Vous n'avez pas cette apparence"
L["ERROR_INVALID_SLOT_OR_ITEM"] = "Emplacement ou objet invalide"
L["ERROR_INVALID_SLOT"] = "Emplacement d'équipement invalide"

-- Tooltips
L["MINIMAP_TOOLTIP"] = "Clic gauche: Ouvrir Transmog\nClic droit: Options"

-- Filters
L["SELECT_ITEM_CLICK"] = "Click to select this item"