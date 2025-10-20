# Godot Workshop Utility
Small utility used to upload content to Steam Workshop with Godot. It is early in development and will most likely undergo a lot of changes. Made to work with the [Godot-ModLoader](https://github.com/GodotModding/godot-mod-loader). Also make sure to have followed this [Steam Workshop implementation guide](https://partner.steamgames.com/doc/features/workshop/implementation) before adding this utility.

## How to use
1. Download the latest release.
2. Distribute it alongside your game's executable.
3. Create a ***steam_data.json*** file containing the ***app_id*** key and set its value to your game's Steam app ID. Include it alongside the GodotWorkshopUtility.exe file.
4. Add a launch option (in the Steamworks back-end, go to ***Edit Steamworks settings*** > ***Installation*** > ***General Installation*** > ***Add new launch option*** and set the parameters as follow:
    - Executable: ***GodotWorkshopUtility.exe***
    - Launch Type: ***Launch Editor***
    - Beta Branch: optionally put the name a specific branch for your modders (so not all players will have to choose a launch option on starting the game)

Launching the executable through Steam should now allow you to upload workshop items.

## Options

1. Add a ***tags*** key to the ***steam_data.json*** file and set its value to an array of tags corresponding to the ones you've set in the Steam backend. (***Edit Steamworks settings*** > ***Workshop*** > ***Tags***)
This will allow users to set tags for their mod. The default maximum number of tags per mod is set to 5 but you can change it by changing the value of the ***max_tags*** variable in ***main.gd***.