#!/usr/bin/env ruby

# Benchmark script for comparing Selenium vs Cuprite performance
require "json"

def run_benchmark(driver_name, runs = 20)
  puts "=== #{driver_name.upcase} BENCHMARK (#{runs} runs) ==="

  times = []

  runs.times do |i|
    print "Run #{i + 1}/#{runs}: "

    start_time = Time.now
    result = `rails test test/system/dashboard_navigation_test.rb 2>&1`
    end_time = Time.now

    duration = end_time - start_time
    times << duration.round(2)

    # Check if tests passed
    if result.include?("0 failures, 0 errors")
      puts "#{duration.round(2)}s ✅"
    else
      puts "#{duration.round(2)}s ❌ (test failed)"
    end
  end

  # Calculate statistics
  avg_time = (times.sum / times.length).round(2)
  min_time = times.min
  max_time = times.max

  # Write raw data to file
  File.write("#{driver_name}_benchmark_data.txt", times.join("\n"))

  # Write summary to file
  summary = {
    driver: driver_name,
    runs: runs,
    times: times,
    average: avg_time,
    min: min_time,
    max: max_time,
    total_time: times.sum.round(2)
  }

  File.write("#{driver_name}_benchmark_summary.json", JSON.pretty_generate(summary))

  puts "\n=== #{driver_name.upcase} RESULTS ==="
  puts "Average: #{avg_time}s"
  puts "Min: #{min_time}s"
  puts "Max: #{max_time}s"
  puts "Total: #{times.sum.round(2)}s"
  puts "Data saved to #{driver_name}_benchmark_data.txt"
  puts "Summary saved to #{driver_name}_benchmark_summary.json"
  puts

  summary
end

def compare_results(selenium_summary, cuprite_summary)
  puts "=== PERFORMANCE COMPARISON ==="
  puts "Selenium average: #{selenium_summary[:average]}s"
  puts "Cuprite average:  #{cuprite_summary[:average]}s"

  improvement = ((selenium_summary[:average] - cuprite_summary[:average]) / selenium_summary[:average] * 100).round(1)

  if improvement > 0
    puts "Cuprite is #{improvement}% faster"
  elsif improvement < 0
    puts "Selenium is #{improvement.abs}% faster"
  else
    puts "No significant difference"
  end

  puts "Time saved per run: #{(selenium_summary[:average] - cuprite_summary[:average]).round(2)}s"
  puts "Time saved over 20 runs: #{(selenium_summary[:total_time] - cuprite_summary[:total_time]).round(2)}s"
end

# Check command line arguments
if ARGV.length == 0
  puts "Usage: ruby benchmark_tests.rb [selenium|cuprite|compare]"
  exit 1
end

case ARGV[0]
when "selenium"
  run_benchmark("selenium", 20)
when "cuprite"
  run_benchmark("cuprite", 20)
when "compare"
  if File.exist?("selenium_benchmark_summary.json") && File.exist?("cuprite_benchmark_summary.json")
    selenium_data = JSON.parse(File.read("selenium_benchmark_summary.json"), symbolize_names: true)
    cuprite_data = JSON.parse(File.read("cuprite_benchmark_summary.json"), symbolize_names: true)
    compare_results(selenium_data, cuprite_data)
  else
    puts "Error: Benchmark data files not found. Run selenium and cuprite benchmarks first."
  end
else
  puts "Invalid option. Use: selenium, cuprite, or compare"
end
