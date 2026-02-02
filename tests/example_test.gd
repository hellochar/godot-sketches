extends GdUnitTestSuite

func test_basic_addition() -> void:
  assert_int(2 + 2).is_equal(4)

func test_string_contains() -> void:
  assert_str("hello world").contains("world")

func test_array_has_size() -> void:
  assert_array([1, 2, 3]).has_size(3)
