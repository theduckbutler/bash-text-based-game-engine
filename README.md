# bash-text-based-game-engine

***This is a passion project that is only worked on every few months, if a commit actually works, it will be explicitly stated***

This 'engine' allows you to create your own stories and worlds, and then play through them in a bash terminal! Allowing you to add people, items, actions, and adjacent rooms, the possibilites are endless. There is a simple default 'world' with just a handful of things to do for a taste of the possible capabilities.

To run, just ensure both ```game.sh``` and ```input.txt``` are in the same directory, and run ```bash game.sh```.
To work on a story, make sure ```build.sh``` and ```input.txt``` are in the same directory.

Capabilities include:

    1. answering questions
    2. situational dialogue (can change on the fly)
    3. interaction with any part of a world
    4. questions that can be asked only once, *or* many times (as desired)
    5. situational naming of any part of a world
    6. multiple possible storylines
    7. item 'detection'
    8. availability coding of items/actions to be viewable but not interactable, etc.
    9. situationally available actions

Also includes:

	Story 'building' application
	   -puts information in format for the engine to understand
	   -can view current actions/items/people/rooms
	   -can add new actions/items/people/rooms

To Do:

    -finish build application
       -edit current actions/items/people/rooms
       -add default built in actions/items (ie. combination lock)
