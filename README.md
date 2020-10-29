Todo
----
This is very simple ruby-based todo-list implementation for the command line. It was made for a coding assignment.

Running
-------
1. Download the [`todo` file](./todo).
2. Make sure you have ruby installed (this was built and tested on ruby 2.6.4)
3. Place the file somewhere in your PATH
4. You should now have access to the `todo` command. Type `todo help` for a list of features.

Persistence
-----------
This app requires data to be stored in a file somewhere. It's just a json file the stores the todos you've created and some identifying metadata. By default, this will be set to `~/.todo/data`, but you can change it by setting the `TODO_DATA_PATH` environment variable.
