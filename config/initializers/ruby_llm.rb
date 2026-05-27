RubyLLM.configure do |config|
  # config.openai_api_key = ENV["OPENAI_API_KEY"]
  # config.openai_api_key = ENV["GEMINI_API_KEY"]
  config.openai_api_key = ENV["GITHUB_TOKEN"]
  config.openai_api_base = "https://models.inference.ai.azure.com"
  # config.gemini_api_key = ENV["GEMINI_API_KEY"]
  # config.gemini_api_base = "https://generativelanguage.googleapis.com/v1"
end
