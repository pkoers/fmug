module PagesHelper
  def render_markdown_content(path)
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true),
      autolink: true,
      fenced_code_blocks: true,
      tables: true
    )

    html = markdown.render(File.read(Rails.root.join("content", path)))
    sanitize(html, tags: %w[p br a em strong code pre ul ol li blockquote h1 h2 h3 h4 h5 h6], attributes: %w[href title])
  rescue Errno::ENOENT
    content_tag(:p, "Content file not found: #{path}")
  end
end
