require 'erb'
require 'fileutils'
require 'gtx'
require 'kramdown'

def command_slug(command)
  return 'index' if command.root_command?

  command.full_name.downcase.tr(' ', '-')
end

def page_slug(page)
  page.name.tr('_', '')
end

def section_slug(group)
  group.name.downcase.tr(' ', '-')
end

def section_title(group)
  [
    '<div class="nav-section-title">',
    group.name.split('-').map(&:capitalize).join(' '),
    '</div>'
  ].join
end

def page_link(page, current_page, cli_nav_html)
  slug = page_slug(page)
  active = slug == current_page ? 'active' : ''
  is_cli_route = /^lct-.+$/.match(current_page) ? true : false 
  [
    '<li>',
    "<a class=\"nav-link #{active}\" href=\"#{slug}.html\">",
    page.name.split('-').map do |word|
      if word.start_with?('_')
        word.upcase.sub('_', '')
      else
        word.capitalize
      end
    end.join(' '),
    '</a>',
      (slug == 'cli-reference' && is_cli_route ? cli_nav_html : ''),
    '</li>'
  ].join
end

def cli_nav_items(command, current_slug)
  command.commands.reject(&:private).map do |subcommand|
    slug = command_slug(subcommand)
    children = cli_nav_items(subcommand, current_slug)
    command_name = slug.gsub('lct-', '').tr('-', ' ')
    active = slug == current_slug ? 'active' : ''
    [
      '<li>',
      "<a class=\"nav-link #{active}\" href=\"#{slug}.html\">#{command_name}</a>",
      '</li>',
      (children.empty? ? '' : children.join),
    ].join
  end
end

def nav_items(groups, current_page, cli_nav_html)
  groups.commands.map do |group|
    pages = group.commands.map do |page|
      page_link(page, current_page, cli_nav_html)
    end

    [
      section_title(group),
      '<ul class="nav-links">',
      pages.join("\n"),
      '</ul>'
    ].join
  end
end

template = "#{source}/page.gtx"
gtx = GTX.load_file(template)
layout = ERB.new(File.read("#{source}/layout.html.erb"))
command_template = "#{source}/command.gtx"
command_gtx = GTX.load_file(command_template)
cli_template = "#{source}/cli.gtx"
cli_gtx = GTX.load_file(cli_template)

assets_target = "#{target}/assets"
FileUtils.mkdir_p(assets_target)
Dir["#{source}/assets/*"].each do |asset|
  FileUtils.cp(asset, assets_target)
end

site = config['x_pages'] || {}
site_title = site['title'] || command.name
tagline = site['tagline'] || command.help
repo_url = site['repo_url']
accent_color = site['accent_color'] || '#4f46e5'
links = site['links'] || []

all_commands = [command] + command.deep_commands.reject(&:private)
pages = command.deep_commands.find { |cmd| cmd.function_name == 'lct_pages' }
all_pages = pages.commands.map(&:commands).flatten

all_pages.each do |cmd|
  slug = page_slug(cmd)
  markdown = gtx.parse(cmd)
  if cmd.name == '_cli-reference'
    cli_markdown = cli_gtx.parse(command)
    markdown += "\n\n" + cli_markdown
  end
  content = Kramdown::Document.new(markdown).to_html

  breadcrumbs = cmd.parents + [cmd.name]
  breadcrumb_html = breadcrumbs.reject { |x| x == 'pages' }.map.with_index do |name, index|
    if index.zero?
      "<a href=\"index.html\">#{command.name}</a>"
    else
      name
    end
  end.join(' / ')

  cli_nav_html = "<ul>#{cli_nav_items(command, slug).join}</ul>"
  nav_html = nav_items(pages, slug, cli_nav_html).join("\n")
  page_title = cmd.name.split('-').map do |word|
    if word.start_with?('_')
      word.upcase.sub('_', '')
    else
      word.capitalize
    end
  end.join(' ')
  description = cmd.summary

  html = layout.result_with_hash(
    content: content,
    nav_html: nav_html,
    page_title: page_title,
    description: description,
    site_title: site_title,
    tagline: tagline,
    repo_url: repo_url,
    accent_color: accent_color,
    links: links,
    breadcrumb_html: breadcrumb_html
  )

  save "#{target}/#{slug}.html", html
end

all_commands.each do |cmd|
  slug = command_slug(cmd)
  markdown = command_gtx.parse(cmd)
  content = Kramdown::Document.new(markdown).to_html

  breadcrumbs = cmd.parents + [cmd.name]
  breadcrumb_html = breadcrumbs.map.with_index do |name, index|
    if index.zero?
      "<a href=\"index.html\">#{command.name}</a>"
    else
      name
    end
  end.join(' / ')

  if cmd.dependencies.any? 
    cmd.dependencies.each do |dep|
      puts "Checking dependency: #{dep.name}"
    end
end

  cli_nav_html = "<ul>#{cli_nav_items(command, slug).join}</ul>"
  nav_html = nav_items(pages, slug, cli_nav_html).join("\n")
  page_title = cmd.full_name
  description = cmd.summary

  html = layout.result_with_hash(
    content: content,
    nav_html: nav_html,
    cli_nav_html: cli_nav_html,
    page_title: page_title,
    description: description,
    site_title: site_title,
    tagline: tagline,
    repo_url: repo_url,
    accent_color: accent_color,
    links: links,
    breadcrumb_html: breadcrumb_html
  )

  save "#{target}/#{slug}.html", html
end
