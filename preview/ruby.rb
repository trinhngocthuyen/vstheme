fastlane_version "2.89.0"
require_relative 'plugins/test_center'

default_platform :ios

$project_dir = File.expand_path('..', __dir__)

platform :ios do
  lane :build_for_testing do
    scan(
      workspace: "#{$project_dir}/GnitSet.xcworkspace",
      scheme: "GnitSet",
      device: get_device,
      clean: false,
      build_for_testing: true,
      buildlog_path: ".artifacts/build",
      sdk: "iphonesimulator",
      configuration: "Debug",
      derived_data_path: "./DerivedData",
      skip_slack: true,
      xcargs: get_xcargs
    )
  end

  lane :ui_test_in_parallel do |options|
    def mask(test)
      comps = test.split("/")
      test_base_name = comps.pop
      comps.join("/") + "_#{test_base_name}/#{test_base_name}"
    end

    tests = []
    tests += (1..2).map { |x| "GnitSetUITests/UITestCaseA/testA#{x}" }
    # tests += (1..5).map { |x| "GnitSetUITests/UITestCaseA/testA#{x}" }
    # tests += (1..5).map { |x| "GnitSetUITests/UITestCaseB/testB#{x}" }
    # tests += (1..5).map { |x| "GnitSetUITests/UITestCaseC/testC#{x}" }
    # tests += (1..5).map { |x| "GnitSetUITests/UITestCaseD/testD#{x}" }
    # tests += (1..5).map { |x| "GnitSetUITests/UITestCaseE/testE#{x}" }
    masked_tests = tests.map { |x| mask(x) }

    _run_ui_test_in_parallel(
      target: "GnitSetUITests",
      only_testing: masked_tests
    )
    parse_xcresult
  end

  lane :unit_test do |options|
    xcargs = get_xcargs
    scan(
      project: "#{$project_dir}/GnitSet.xcodeproj",
      scheme: "GnitSet",
      device: get_device,
      sdk: "iphonesimulator",
      configuration: "Debug",
      derived_data_path: "./DerivedData",
      buildlog_path: ".artifacts/unit_test",
      skip_slack: true,
      xcargs: xcargs,
      only_testing: ['GnitSetTests']
    )
  end
end

lane :parse_xcresult do |options|
  xcresult_file = get_xcresult_files[0]
  Actions.sh("xcparse logs #{get_xcresult_files[0].shellescape} out") unless xcresult_file.nil?
end

def _run_ui_test_in_parallel(options)
  test_target = options[:target]
  only_testing = options[:only_testing]

  unless only_testing.empty?
    n_parallel_testing_workers = Integer(ENV["NUM_OF_UI_TEST_PARALLEL_WORKERS"] || 2)
    raise "No. of parallel workers should not be greater than 4 due to limited CPU usage" if n_parallel_testing_workers > 4
    xcargs = get_xcargs
    xcargs += " -parallel-testing-enabled YES -parallel-testing-worker-count #{n_parallel_testing_workers}"

    failed_tests = []
    auto_retry_scan(
      project: "#{$project_dir}/GnitSet.xcodeproj",
      scheme: "GnitSet",
      device: get_device,
      test_without_building: true,
      sdk: "iphonesimulator",
      configuration: "Debug",
      xctestrun: get_xctestrun_file,
      try_count: 0,
      derived_data_path: "./DerivedData",
      output_directory: "./.fastlane/test_output",
      buildlog_path: ".artifacts/ui_test",
      only_testing: only_testing,
      skip_slack: true,
      xcargs: xcargs,
      xcpretty_args: "--test-target #{test_target}",
      testrun_completed_block: lambda { |testrun_info|
        try_count = testrun_info[:try_count]
        failed_tests += testrun_info[:failed]
        puts "--- try_count: #{try_count} --> #{failed_tests}"
      }
    )
  end
end

def get_xcargs(options={})
  xcargs = []
  xcargs << "-UseModernBuildSystem=NO" unless options[:new_build_system]
  xcargs << "OTHER_CODE_SIGN_FLAGS=--keychain=#{keychain_path}" if options[:custom_key_chain]
  xcargs << "OTHER_SWIFT_FLAGS='-Xfrontend -debug-time-function-bodies'" if options[:debug_time_function_bodies]
  xcargs.join(" ")
end

def get_device
  # "DaxIOS-XC10-1-iP7-1"
  "iPhone 8"
end

def get_xctestrun_file
  # Dir.glob("DerivedData/Build/Products/GnitSet*.xctestrun")[0]
  Dir.glob("/Users/chris.thuyen/Library/Developer/Xcode/DerivedData/Build/Products/GnitSet*.xctestrun")[0]
end

def get_xcresult_files
  Dir.glob("DerivedData/Logs/Test/*.xcresult")
end




