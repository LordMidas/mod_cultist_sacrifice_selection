local modInfo = {
	ID = "mod_cultist_sacrifice_selection",
	Name = "Cultist Sacrifice Selection",
	Version = "1.0.0"
};

local mh = ::Hooks.register(modInfo.ID, modInfo.Version, modInfo.Name);
mh.require("mod_msu");

mh.queue(">mod_msu", function() {
	local msuMod = ::MSU.Class.Mod(modInfo.ID, modInfo.Version, modInfo.Name);
	msuMod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.GitHub, "https://github.com/LordMidas/mod_cultist_sacrifice_selection");
	msuMod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.GitHub);
	msuMod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.NexusMods, "https://www.nexusmods.com/battlebrothers/mods/765");

	local page = msuMod.ModSettings.addPage("General");
	page.addEnumSetting("CultistSacrificeSelection", "Non-Cultist Trait Only", ["All", "Non-Cultist Only", "Non-Cultist Trait Only"], "Cultist Sacrifice Selection", "Choose which characters can be chosen as sacrifice in the cultist sacrifice event.\n\nAll: Same as vanilla. Any character can be chosen.\n\nNon-Cultist Only: Characters with the Cultist or Converted Cultist backgrounds etc. are excluded.\n\nNon-Cultist Trait Only: Cultists can be chosen as sacrifice, but those with cultist specific traits e.g. Acolyte, Chosen, Zealot, Fanatic, Prophet of Davkul etc. are excluded.");

	mh.hook("scripts/events/events/dlc4/cultist_origin_sacrifice_event", function(q) {
		q.isBroValidForSacrifice <- { function isBroValidForSacrifice( _bro )
		{
			switch (::getModSetting(modInfo.ID, "CultistSacrificeSelection").getValue())
			{
				case "All":
					return true;

				case "Non-Cultist Only":
					return _bro.getBackground().getID().find("cultist") == null;

				case "Non-Cultist Trait Only":
					foreach (t in _bro.getSkills().getAllSkillsOfType(::Const.SkillType.Trait))
					{
						if (!t.isType(::Const.SkillType.Background) && t.getID().find("cultist") != null)
						{
							return false;
						}
					}
			}

			return true;
		}}.isBroValidForSacrifice;

		// Overwrite because we need to change the logic for selection of the bros.
		// The function is the same as vanilla except the commented parts.
		q.onUpdateScore = @() { function onUpdateScore()
		{
			if (!::Const.DLC.Wildmen)
			{
				return;
			}

			if (::World.getTime().Days <= 5)
			{
				return;
			}

			if (::World.Assets.getOrigin().getID() != "scenario.cultists")
			{
				return;
			}

			// We filter the brothers list to remove bros who are invalid for sacrifice.
			local self = this;
			local brothers = ::World.getPlayerRoster().getAll().filter(@(_, _bro) self.isBroValidForSacrifice(_bro));

			// Vanilla has < 4. We drop it to 2 because with selection option other than "All"
			// because then the number of valid bros can be small.
			if (brothers.len() < (::getModSetting(modInfo.ID, "CultistSacrificeSelection").getValue() == "All" ? 4 : 2))
			{
				return;
			}

			brothers.sort(function ( _a, _b )
			{
				if (_a.getXP() < _b.getXP())
				{
					return -1;
				}
				else if (_a.getXP() > _b.getXP())
				{
					return 1;
				}

				return 0;
			});
			local r = ::Math.rand(0, ::Math.min(2, brothers.len() - 1));
			this.m.Sacrifice1 = brothers[r];
			brothers.remove(r);
			r = ::Math.rand(0, ::Math.min(2, brothers.len() - 1));
			this.m.Sacrifice2 = brothers[r];
			this.m.Score = 50 + (::World.getTime().Days - this.m.LastTriggeredOnDay);
		}}.onUpdateScore;
	});
});
