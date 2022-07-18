Settings -> The settings files (ServerHostSettings.json, ServerGameSettings.json, ServerVoipSettings.json)

SettingsMap
Maps a Setting Name to a list of possible values.
Used to support AutoCompletion.
Powers both Settings and Options values.

Properties -> The properties file (foo.json)
Provides a mutex-protected interface into reading and writing the values from disk.

Options -> User-Configurable Properties
Provides a vrmset-compatible interface for tweakable options which are stored using Properties