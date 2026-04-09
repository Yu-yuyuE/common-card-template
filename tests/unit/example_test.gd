extends GdUnitTestSuite

# This is an example unit test file to ensure the test framework is recognized by the CI/CD pipeline.
# Run with GdUnit4.

func test_example_math():
	assert_int(1 + 1).is_equal(2)

func test_fail_intentional_placeholder():
	# Skip or pass
	assert_bool(true).is_true()
