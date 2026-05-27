module ApplicationHelper
  def markdown(text)
    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      hard_wrap: true
    )
    extensions = {
      autolink: true,
      fenced_code_blocks: true,
      tables: true,
      strikethrough: true
    }
    Redcarpet::Markdown.new(renderer, extensions)
                       .render(text)
                       .html_safe
  end
end
