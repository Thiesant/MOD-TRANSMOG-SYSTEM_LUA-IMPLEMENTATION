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
L["SEARCH_NAME_DESCRIPTION"] = ": Entrer le nom d'un objet (français)"
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
L["INVALID_SLOT"] = "Emplacement invalide"
L["INVALID_SLOT_OR_ITEM"] = "Emplacement ou objet invalide"
L["INVALID_SLOT_OR_ENCHANT"] = "Emplacement ou enchantement invalide"
L["SLOT_NOT_ENCHANT_ELIGIBLE"] = "Cet emplacement ne peut pas avoir de transmog d'enchantement"
L["INVALID_ENCHANT_ID"] = "ID d'enchantement invalide"
L["ENCHANT_CACHE_NOT_READY"] = "Cache d'enchantements pas prêt, veuillez patienter"
L["NOT_IN_COLLECTION"] = "Apparence non collectée"
L["ITEM_NOT_ELIGIBLE"] = "Objet non éligible pour la transmogrification"

-- Filters
L["SELECT_ITEM_CLICK"] = "Cliquez pour sélectionner cet objet"
L["FILTER_ALL"] = "Tous"
L["FILTER_COLLECTED"] = "Collectés"
L["FILTER_UNCOLLECTED"] = "Non collectés"

-- Set Management
L["SET_NEW"] = "Nouvel ensemble..."
L["SET_SELECT"] = "Sélectionner"
L["SET_DEFAULT_NAME"] = "Ensemble %d"
L["SET_SAVE"] = "Sauver"
L["SET_DELETE"] = "Suppr"
L["SET_APPLY"] = "Appliquer"
L["SET_SAVE_PROMPT"] = "Nom de l'ensemble:"
L["SET_SAVED"] = "Ensemble '%s' sauvegardé!"
L["SET_LOADED"] = "Ensemble '%s' chargé dans l'aperçu"
L["SET_DELETED"] = "Ensemble #%d supprimé"
L["SET_APPLIED"] = "Ensemble '%s' appliqué!"
L["SET_ERROR"] = "Opération sur l'ensemble échouée"
L["SET_FULL"] = "|cffff0000[Transmog]|r Tous les emplacements sont pleins. Supprimez un ensemble d'abord."
L["SET_NO_SELECTION"] = "|cffff0000[Transmog]|r Aucun objet sélectionné. Cliquez sur des objets dans l'aperçu pour les sélectionner."
L["SET_SELECT_FIRST"] = "|cffff0000[Transmog]|r Sélectionnez un ensemble d'abord."
L["SET_DELETE_CONFIRM"] = "Supprimer cet ensemble?"
L["SET_SAVE_TOOLTIP"] = "Sauvegarder les objets sélectionnés comme nouvel ensemble"
L["SET_DELETE_TOOLTIP"] = "Supprimer l'ensemble sélectionné"
L["SET_APPLY_TOOLTIP"] = "Appliquer cet ensemble comme transmog actif\n(Seules les apparences collectées seront appliquées)"
L["APPLY_HINT"] = "Sélectionnez une apparence et Shift+Clic pour l'appliquer"
L["APPLY_ALL_TOOLTIP"] = "Appliquer Toutes les Sélections"
L["APPLY_ALL_DESC"] = "Applique tous les objets avec bordure cyan à votre personnage"
L["APPLY_ALL_SUCCESS"] = "|cff00ff00[Transmog]|r %d apparences appliquées"
L["APPLY_ALL_NONE"] = "|cffff0000[Transmog]|r Aucune apparence sélectionnée à appliquer"
L["APPLY_SINGLE_HINT"] = "|cff00ff00Shift+Clic|r sur un objet de la grille pour appliquer uniquement cette apparence"

-- Reset Button
L["RESET_TOOLTIP"] = "Réinitialiser l'Aperçu"
L["RESET_DESC"] = "Réinitialise la cabine d'essayage à votre apparence actuelle"
L["RESET_RIGHTCLICK_HINT"] = "|cffff0000Clic droit|r pour effacer TOUTES les transmogs actives"
L["CLEAR_ALL_SUCCESS"] = "|cff00ff00[Transmog]|r %d emplacements de transmog effacés"
L["CLEAR_ALL_NONE"] = "|cff00ff00[Transmog]|r Aucune transmog active à effacer"

-- Mode Toggle
L["MODE_ITEM"] = "Objets"
L["MODE_ENCHANT"] = "Enchants"
L["MODE_TOGGLE_TOOLTIP_ITEM"] = "Mode Transmog Objets"
L["MODE_TOGGLE_TOOLTIP_ENCHANT"] = "Mode Transmog Enchantements"
L["MODE_TOGGLE_DESC_ITEM"] = "Cliquez pour passer au mode Enchantements"
L["MODE_TOGGLE_DESC_ENCHANT"] = "Cliquez pour passer au mode Objets"
L["MODE_ENCHANT_NOTE"] = "Seuls les emplacements d'armes peuvent avoir des visuels d'enchantement"
L["ENCHANT_MODE"] = "Mode Enchant"

-- Enchantment Strings
L["ENCHANT_CATEGORY"] = "Catégorie"
L["ENCHANT_ACTIVE"] = "|cff00ff00Actuellement Actif|r"
L["CLEAR_ENCHANT"] = "|cffff0000Clic droit pour retirer|r"
L["APPLY_ENCHANT_SHIFT_CLICK"] = "|cff00ff00Shift+Clic:|r Appliquer le visuel d'enchantement"
L["ENCHANT_APPLIED"] = "Visuel d'enchantement appliqué!"
L["ENCHANT_REMOVED"] = "Visuel d'enchantement retiré!"
L["ENCHANT_COLLECTION_LOADED"] = "Collection d'enchantements chargée: %d visuels"

-- Enchant Categories
L["Runeforge"] = "Forge de Rune"
L["Fire"] = "Feu"
L["Frost"] = "Givre"
L["Nature"] = "Nature"
L["Arcane"] = "Arcane"
L["Holy"] = "Sacré"
L["Shadow"] = "Ombre"
L["Physical"] = "Physique"
L["Shaman"] = "Chaman"

-- Settings Panel
L["SETTINGS"] = "Paramètres"
L["BACK"] = "Retour"
L["SETTINGS_TITLE"] = "Paramètres Transmog"
L["SETTINGS_TOOLTIP"] = "Paramètres"
L["SETTINGS_DESC"] = "Cliquez pour ouvrir les paramètres"
L["BACK_TOOLTIP"] = "Retour aux objets"
L["BACK_DESC"] = "Cliquez pour revenir à la grille d'objets"

-- Settings Sections
L["SETTINGS_DISPLAY"] = "Paramètres d'affichage"
L["SETTINGS_TOOLTIP_SECTION"] = "Paramètres des infobulles"
L["SETTINGS_INFO"] = "Informations"

-- Display Settings
L["SETTING_BACKGROUND"] = "Fond de la cabine d'essayage :"
L["SETTING_SET_PREVIEW_BG"] = "Fond de l'aperçu des ensembles :"
L["SETTING_BG_AUTO"] = "Auto (Classe)"
L["SETTING_BG_SELECT"] = "Sélectionner le fond"
L["SETTING_PREVIEW_MODE"] = "Mode d'aperçu de la grille :"
L["SETTING_PREVIEW_CLASSIC"] = "Classique (WoW 3.3.5)"
L["SETTING_PREVIEW_HD"] = "HD (Requiert un patch de modèles HD)"

-- Tooltip Settings
L["SETTING_SHOW_ITEM_ID"] = "Afficher l'ID de l'objet dans l'infobulle"
L["SETTING_SHOW_DISPLAY_ID"] = "Afficher le Display ID dans l'infobulle"
L["SETTING_SHOW_COLLECTED"] = "Afficher \"Apparence collectée\" dans l'infobulle"
L["SETTING_SHOW_NEW"] = "Afficher \"Nouvelle apparence\" dans l'infobulle"

-- Grid Preview Settings
L["SETTINGS_GRID_PREVIEW"] = "Paramètres d'aperçu de la grille"
L["SETTING_HIDE_HAIR_CLOAK"] = "Masquer les cheveux sur l'aperçu des capes"
L["SETTING_HIDE_HAIR_CHEST"] = "Masquer cheveux/barbe sur l'aperçu des torses"
L["SETTING_HIDE_HAIR_SHIRT"] = "Masquer cheveux/barbe sur l'aperçu des chemises"
L["SETTING_HIDE_HAIR_TABARD"] = "Masquer cheveux/barbe sur l'aperçu des tabards"

-- Border Settings
L["SETTINGS_UI"] = "Paramètres de l'interface utilisateur"
L["SETTING_SHOW_TRANSMOG_BORDERS"] = "Afficher les bordures de transmogrification dans les cadres de Personnage/Inspection"

-- Settings Info
L["SETTINGS_INFO_TEXT"] = "|cff888888Paramètres globaux|r s'appliquent à tous les personnages.\n|cff888888Paramètres par personnage|r (fond, mode d'aperçu) sont sauvegardés par personnage.\n\nLes paramètres sont sauvegardés automatiquement."

-- Class Names (for background dropdown)
L["CLASS_WARRIOR"] = "Guerrier"
L["CLASS_PALADIN"] = "Paladin"
L["CLASS_HUNTER"] = "Chasseur"
L["CLASS_ROGUE"] = "Voleur"
L["CLASS_PRIEST"] = "Prêtre"
L["CLASS_DEATHKNIGHT"] = "Chevalier de la mort"
L["CLASS_SHAMAN"] = "Chaman"
L["CLASS_MAGE"] = "Mage"
L["CLASS_WARLOCK"] = "Démoniste"
L["CLASS_MONK"] = "Moine"
L["CLASS_DRUID"] = "Druide"

-- Background Dropdown Separators
L["SETTING_BG_CLASSES"] = "Classes"
L["SETTING_BG_RACES"] = "Races"
L["SETTING_BG_ALLIED"] = "Races alliées"

-- Race Names (for background dropdown)
L["RACE_HUMAN"] = "Humain"
L["RACE_DWARF"] = "Nain"
L["RACE_NIGHTELF"] = "Elfe de la nuit"
L["RACE_GNOME"] = "Gnome"
L["RACE_DRAENEI"] = "Draeneï"
L["RACE_WORGEN"] = "Worgen"
L["RACE_ORC"] = "Orc"
L["RACE_SCOURGE"] = "Mort-vivant"
L["RACE_TAUREN"] = "Tauren"
L["RACE_TROLL"] = "Troll"
L["RACE_BLOODELF"] = "Elfe de sang"
L["RACE_GOBLIN"] = "Gobelin"
L["RACE_PANDAREN"] = "Pandaren"

-- Allied Race Names
L["RACE_VOIDELF"] = "Elfe du Vide"
L["RACE_LIGHTFORGED"] = "Draeneï sancteforge"
L["RACE_DARKIRON"] = "Nain sombrefer"
L["RACE_KULTIRAN"] = "Kultirassien"
L["RACE_MECHAGNOME"] = "Mécagnome"
L["RACE_NIGHTBORNE"] = "Sacrenuit"
L["RACE_HIGHMOUNTAINTAUREN"] = "Tauren de Haut-Roc"
L["RACE_MAGHAR"] = "Orc Mag'har"
L["RACE_ZANDALARI"] = "Troll zandalari"
L["RACE_VULPERA"] = "Vulpérin"
L["RACE_DRACTHYR"] = "Dracthyr"
L["RACE_EARTHEN"] = "Terrestre"

-- Quality Names
L["QUALITY_ALL"] = "Tous"
L["QUALITY_POOR"] = "Médiocre"
L["QUALITY_COMMON"] = "Commun"
L["QUALITY_UNCOMMON"] = "Inhabituel"
L["QUALITY_RARE"] = "Rare"
L["QUALITY_EPIC"] = "Épique"
L["QUALITY_LEGENDARY"] = "Légendaire"
L["QUALITY_HEIRLOOM"] = "Héritage"

-- Sets Preview Panel
L["SETS_PREVIEW"] = "Ensembles"
L["SETS_PREVIEW_TITLE"] = "Aperçu des Ensembles Sauvegardés"
L["SETS_PREVIEW_TOOLTIP"] = "Aperçu des Ensembles"
L["SETS_PREVIEW_DESC"] = "Voir tous vos ensembles de transmog sauvegardés avec l'aperçu en cabine d'essayage"
L["NO_SETS_SAVED"] = "Aucun ensemble sauvegardé.\nUtilisez le bouton Sauver pour sauvegarder vos sélections actuelles."
L["SETS_COUNT"] = "%d ensembles"
L["SCROLL_INDICATOR"] = "Défilement: %d/%d"

-- Copy Player Appearance
L["COPY_PLAYER"] = "Copier Joueur"
L["COPY_PLAYER_TOOLTIP"] = "Copier l'Apparence d'un Joueur"
L["COPY_PLAYER_DESC"] = "Ciblez un joueur et cliquez pour copier son équipement visible dans votre sélection."
L["COPY_PLAYER_PROMPT"] = "Entrez le nom du joueur à copier\n(ou ciblez d'abord un joueur):"
L["COPY"] = "Copier"
L["COPY_PLAYER_SUCCESS"] = "|cff00ff00[Transmog]|r %d objets copiés depuis l'apparence de %s."
L["COPY_PLAYER_HINT"] = "|cff00ff00[Transmog]|r Utilisez le bouton Sauver pour enregistrer celui-ci comme ensemble."

-- Merge by Display ID feature
L["SETTING_MERGE_BY_DISPLAY_ID"] = "Fusionner les objets par apparence (Display ID)"
L["SHARED_APPEARANCE"] = "|cffFFD700Apparence partagée sur les objets :|r"
L["SETTING_SHOW_SHARED_APPEARANCE"] = "Afficher les apparences partagées dans les infobulles"