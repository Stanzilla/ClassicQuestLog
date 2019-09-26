Classic Quest Log

This addon restores the old quest log with the list of quests on the left and details on the right.

As most have already noticed, the old quest log is gone and we have a new map+quest log hybrid since Warlords of Draenor launched.

This addon's initial behavior is to commandeer your quest log key binding and micro button to toggle the new log.  It should be a familiar enough experience once you log in.

If you decide you want to keep using the new default log alongside this addon, you can:
- Open the map via key binding (M is default key) will display the new map+quest log hybrid.
- Click 'Show Map' in the upper right of the Classic Quest Log, it will jump to the map of the quest's zone with the attached new style quest log.
- If that's not enough and you only want to use the Classic Quest Log occasionally, go into Key Bindings -> AddOns -> Classic Quest Log and set a binding to toggle this addon's window.  Once a binding is set, it will revert the behavior of the default quest log binding and quest micro button to its map+quest default behavior.

There are a few minor changes from the true old quest log:
- Instead of saying (Completed) or (Daily) beside each quest name, they are now represented by icons just like the new log.
- There are a few other options in the Options button at the bottom of the window, such as the ability to move the window around the screen or to resize the height of the window.

1.4.2 12/24/2018
- Added a header above war campaign quests in the left pane of the quest log.
- Updated toc for 8.1.

1.4.1 07/07/2018
- Fix for Lua error when attempting to display quest portraits.

1.4.0 06/09/2018
- Update for Battle for Azeroth client.

1.3.4 08/29/2017
- Fix for PlaySound when sharing a quest in 7.3.
- toc updated for 7.3.

1.3.3 08/07/2017
- Fix for coming 7.3 PlaySound change

1.3.2 05/25/2017
- Quest NPC portraits will now display when a quest with a portrait is selected.

1.3.1 05/13/2017
- While using ElvUI or Aurora, a new option "Use Classic Skin" is available to prevent skinning for those UIs.
- Reworked internal quest selection/update process.
- Fix for the abandon quest dialog dismissing without an obvious reason.
- Fix for quest detail pane scrolling to top without an obvious reason.

1.3.0 05/12/2017
- The Solid Background option changed to Dark Background. It now makes the details portion light text on a dark background.
- ElvUI skin is applied if ElvUI is enabled.
- Aurora skin is applied if Aurora is enabled.

1.2.11 04/12/2017
- When shift+clicking a quest on the objective tracker to stop tracking it will no longer summon the quest log.

1.2.10 04/09/2017
- Clicking an objective in the objective tracker will summon the quest log instead of the world map.

1.2.9 03/28/2017
- toc update for 7.2 patch

1.2.8 12/01/2016
- Fix for +/- buttons on quest headers not properly indicating if the header is collapsed.

1.2.7 10/27/2016
- Fix for quests not linking to chat.
- Fix for "missing header!" and extra quests:
  - Quests flagged as hidden will now be hidden.
  - Headers that contain only hidden quests will be hidden also.

1.2.6 10/24/2016
- toc update for 7.1 patch.

1.2.5 09/18/2016
- Added open and close sound to the window.

1.2.4 09/09/2016
- Fix for hitting "Close" button breaking the "panel-ness" of the window.
- Fix for number of groupmates on a quest remaining when a quest category is collapsed.

1.2.3 08/05/2016
- If the default quest frame is up while summoning Classic Quest Log, the default quest frame will be hidden.

1.2.2 07/19/2016
- 7.0 release

1.2.1 07/14/2016
- Added option "Solid Background" to make the background behind text solid to improve readability.
- Hitting ESCape while the little options window is open will close options without closing the whole quest log.
- Fix for opening map or details window from another source sometimes breaking Classic Quest Log's panel behavior.

1.2.0 06/10/2016
- Like the original quest window, the default behavior of the Classic Quest Log is now to dock on the left and move over as default UI panels appear.
- Added Options button to bottom of the window with the following options:
- Undock Window: This will allow dragging the window around the screen.
- Lock Window Position: While the window is undocked, this will prevent moving the window unless Shift is held.
- Show Resize Grip: This will allow resizing the height of the quest window.
- Show Quest Levels: This is the old option to show levels alongside listed quests.
- Show Quest Tooltips: This is the old option to show tooltips when you mouseover listed quests.

1.1.1 05/28/2016
- Quest tooltips are more complete.

1.1.0 05/12/2016
- toc update for 7.0 Legion beta
- Fix for lua error at QuestInfo.lua:45

1.0.6 06/22/2015
- toc update for 6.2 patch

1.0.5 02/24/2015
- toc update for 6.1 patch

1.0.4 02/21/2015
- Headers are collapsable.
- Expand/Collapse All button.
- Fix for bug where a separate key binding is defined but addon is still overriding default key/button.
- Multiple quest update events within one frame will update the log once instead of for each event.

1.0.3 10/14/2014 fix for error when grouped
1.0.2 10/12/2014 fix for blank reward icons, log hides when default standalone quest panel shows, 6.0 patch
1.0.1 09/19/2014 initial release