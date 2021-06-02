class ProfileJSON < RSpec::Core::Formatters::JsonFormatter
  RSpec::Core::Formatters.register self

  def initialize(*args)
    RSpec.configure{|c| c.add_formatter(:progress)}
    super(*args)
  end

  def close(_notification)
    collected_output = []

    @output_hash[:examples].map do |ex|
      collected_output << {
        :description => ex[:full_description],
        :staus => ex[:status],
        :run_time => ex[:run_time],
        :exception => ex[:exception]
      }
    end

    require 'json'
    output.puts("== BEGIN_JSON_PROFILE ==")
    output.puts JSON.pretty_generate(collected_output.sort_by{|x| x[:run_time]})
    output.puts("== END_JSON_PROFILE ==")
  end
end
