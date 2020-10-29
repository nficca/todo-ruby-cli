load "todo"
require "test/unit"

class TestTodo < Test::Unit::TestCase
  def setup
    File.delete(Todo::TODO_DATA_PATH) if File.exist?(Todo::TODO_DATA_PATH)
    @todo = Todo.new
  end
  
  def teardown
    File.delete(Todo::TODO_DATA_PATH) if File.exist?(Todo::TODO_DATA_PATH)
  end

  def test_no_subcommand
    stdout, stderr = @todo.handle([])

    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_invalid_subcommand
    stdout, stderr = @todo.handle(["foo"])

    assert_equal(stderr, "No valid subcommand `foo`.")
    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_help
    stdout, stderr = @todo.handle(["help"])

    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_list_no_datafile
    stdout, stderr = @todo.handle(["list"])

    assert_equal(stdout, "No todos!")
  end

  def test_list_empty_datafile
    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write("") }

    stdout, stderr = @todo.handle(["list"])

    assert_equal(stdout, "No todos!")
  end

  def test_list_empty_json_object
    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write("{}") }

    stdout, stderr = @todo.handle(["list"])

    assert_equal(stdout, "No todos!")
  end

  def test_list_basic
    stdout, stderr = @todo.handle(["list"])

    data = {
      "1234" => {priority: 1, text: "Foo"},
      "4567" => {priority: 3, text: "Bar"}
    }

    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write(data.to_json) }

    stdout, stderr = @todo.handle(["list"])

    expected_output = <<~EOS
    Priority  ID    Todo
           1  1234  Foo
           3  4567  Bar

    Missing priorities:
    2
    EOS

    assert_equal(stdout, expected_output)
  end

  def test_list_no_missing_priorities
    stdout, stderr = @todo.handle(["list"])

    data = {
      "1234" => {priority: 1, text: "Foo"},
      "4567" => {priority: 2, text: "Bar"}
    }

    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write(data.to_json) }

    stdout, stderr = @todo.handle(["list"])

    expected_output = <<~EOS
    Priority  ID    Todo
           1  1234  Foo
           2  4567  Bar
    EOS

    assert_equal(stdout, expected_output)
  end

  def test_list_complex
    stdout, stderr = @todo.handle(["list"])

    data = {
      "4567" => {priority: 9, text: "Foo"},
      "as43" => {priority: 7, text: "Bar"},
      "1234" => {priority: 12, text: "This is a test for a todo list."},
      "92f2" => {priority: 5, text: "1251"},
      "rc23" => {priority: 16, text: ".;.p35..5===ppp..r2.[[.12=2-0{}`.`"},
      "8b42" => {priority: 12, text: ""}
    }

    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write(data.to_json) }

    stdout, stderr = @todo.handle(["list"])

    expected_output = <<~EOS
    Priority  ID    Todo
           5  92f2  1251
           7  as43  Bar
           9  4567  Foo
          12  1234  This is a test for a todo list.
          12  8b42  
          16  rc23  .;.p35..5===ppp..r2.[[.12=2-0{}`.`

    Missing priorities:
    1, 2, 3, 4, 6, 8, 10, 11, 13, 14, 15
    EOS

    assert_equal(stdout, expected_output)
  end

  def test_new_no_arguments
    stdout, stderr = @todo.handle(["new"])

    assert_equal(stderr, "Must pass an integer priority and text string.")
    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_new_no_text
    stdout, stderr = @todo.handle(["new", "1"])

    assert_equal(stderr, "Must pass an integer priority and text string.")
    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_new_invalid_priority
    stdout, stderr = @todo.handle(["new", "qsf", "Foo"])

    assert_equal(stderr, "Must pass an integer priority and text string.")
    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_new_no_datafile
    stdout, stderr = @todo.handle(["new", "1", "Foo"])

    stored_data = JSON.parse(File.read(Todo::TODO_DATA_PATH))

    assert_equal(stored_data.keys.count, 1)
    assert_equal(stored_data.keys.first.length, 4)
    assert_equal(stored_data[stored_data.keys.first], {"priority" => 1, "text" => "Foo"})

    assert_equal(stdout, "Created todo with priority 1: \"Foo\".")
  end

  def test_new_existing_datafile
    data = {"asdf" => {priority: 3, text: "Bar"}}

    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write(data.to_json) }

    stdout, stderr = @todo.handle(["new", "1", "Foo"])

    stored_data = JSON.parse(File.read(Todo::TODO_DATA_PATH))

    assert_equal(stored_data.keys.count, 2)

    created_key = stored_data.keys.detect { |k| k != "asdf" }

    assert_equal(stored_data["asdf"], {"priority" => 3, "text" => "Bar"})
    assert_equal(stored_data[created_key], {"priority" => 1, "text" => "Foo"})

    assert_equal(stdout, "Created todo with priority 1: \"Foo\".")
  end

  def test_del_no_todo_id
    stdout, stderr = @todo.handle(["del"])

    assert_equal(stderr, "Must pass a valid todo id. See valid todo ids via the `list` subcommand.")
    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_del_no_datafile
    stdout, stderr = @todo.handle(["del", "1234"])

    assert_equal(stderr, "Must pass a valid todo id. See valid todo ids via the `list` subcommand.")
    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_del_no_todo_for_given_id
    data = {"4567" => {priority: 1, text: "Foo"}}

    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write(data.to_json) }

    stdout, stderr = @todo.handle(["del", "1234"])

    assert_equal(stderr, "Must pass a valid todo id. See valid todo ids via the `list` subcommand.")
    assert_equal(stdout, Todo::HELP_TEXT)
  end

  def test_del_valid_todo_id
    data = {"1234" => {priority: 1, text: "Foo"}, "othr" => {priority: 3, text: "Bar"}}

    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write(data.to_json) }

    stdout, stderr = @todo.handle(["del", "1234"])

    stored_data = JSON.parse(File.read(Todo::TODO_DATA_PATH))
  
    assert_equal(stored_data, {"othr" => {"priority" => 3, "text" => "Bar"}})
    assert_equal(stdout, "Deleted todo with priority 1: \"Foo\".")
  end

  def test_clear
    data = {"1234" => {priority: 1, text: "Foo"}, "othr" => {priority: 3, text: "Bar"}}

    File.open(Todo::TODO_DATA_PATH, "w") { |f| f.write(data.to_json) }

    stdout, stderr = @todo.handle(["clear"])

    assert_equal(stdout, "Cleared all todos.")
    assert_equal(File.read(Todo::TODO_DATA_PATH), "{}")
  end
end
