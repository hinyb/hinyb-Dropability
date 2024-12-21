v3.1.5
* Add some functions for SkillChest.
* Add some check and lazy initialization for SkillModifierData.
* Fix the wrong warning message when adding a modifier.
* Fix the crash game bug.

v3.1.4
* Update to RMT 1.2.0.
* A small change to Instance_ext

v3.1.3
* A small change for SkillSeeker.

v3.1.2
* Some changes for SkillSeeker.
* Fix bar again.

v3.1.1
* Fix monsterShamGX's summons behaving weirdly. 
    * However, now they are unable to be attacked, I think it is hard to resolve and they are too weak, so I decided to keep it as is.
* Add some functions for SkillChest.

v3.1.0
* Refactor SkillModifier.
* Fix incorrect usage of log.error.
* Fix the skill with flux_slot_index can't drop.

v3.0.7
* Delete unsafe sync_call.
* Now SkillPickup will sync stock and remove useless sync code.
* Fix random_skill_blacklist have wrong reload skill_id.

v3.0.6
* Fix memory leak caused by modifier.

v3.0.5
* Fix after_image's incorrect proability.
* Fix can't get umbraskills' slot_index.
* Add useless skills to blacklist.
* Balance echo_item.
* Fix life_burn can't trigger at correct time.
* Add max_stack check.
* Fix my brain dead bar code. Now it should work porperly in multiplayer and singleplayer.
* Fix SniperDrone, now don't need LendDrone to use SniperV. Later will remove the code in LendDrone.
* Move SkillModifier_Regs to SkillChest.

v3.0.4
* Balance echo_item.
* Fix can't drop mob skill.

v3.0.3
* Fix set_and_sync_inst_from_table can't work in single
* Fix monsterShamGX
* Add after_image modifier.
* Improve echo_item's implementation.

v3.0.2
* Balance the HANDY's skill with life_burn.
* Fix scrap_bar's compatibility issue.
* Fix life_burn's sync bug

v3.0.1
* Fix singleplayer compatibility issues.
* Finish random_skill_blacklist. Now it shouldn't have issues. If you find some, please feedback on github.
* Add life_burn modifier.
* Fix sync bug.

v3.0.0
* Improve the skillPickup, now It can have more modifiers.
* I'm not good at balancing, so It may have many issues.
* Fix the compatibility issues with the other mods.
* Improve the fixing way of HANDY's compatibility issues.

v2.0.8
* Fix memory leak. But still have more places for optimization.

v2.0.7
* Code cleanup.
* Try using envy to manage the environment.

v2.0.6
* Delete the test funciton I forgot to remove.
* Fix HANDY's compatibility issues with a terrible way.
* Update to new network api.

v2.0.5
* Fix the incorrect way of calling anonymous funciton

v2.0.4
* Fix miner's heat bar and drifter's scrap bar, now they should work properly.

v2.0.3
* Fix bug that causes crash. But still have some compatibility issues.

v2.0.2
* Fix bar's incorrect behaive.
* Find more compatibility issues and correct the description.

v2.0.1
* Fix bug of the miner's ability.

v2.0.0
* Add ability to drop ability!

v1.0.3
* Add tooltip check to avoid wrong behaive.

v1.0.2
* Fix Poor duplicator can duplicate items.

v1.0.1
* Fix description.

v1.0.0
* First upload.