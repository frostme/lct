require 'erb'
require 'fileutils'
require 'gtx'
require 'kramdown'

def command_slug(command)
  return 'index' if command.root_command?

  command.full_name.downcase.tr(' ', '-')
end

def nav_items(command, current_slug)
  command.commands.reject(&:private).map do |subcommand|
    slug = command_slug(subcommand)
    children = nav_items(subcommand, current_slug)
    active = slug == current_slug ? 'active' : ''
    [
      '<li>',
      "<a class=\"nav-link #{active}\" href=\"#{slug}.html\">#{subcommand.name}</a>",
      (children.empty? ? '' : "<ul>#{children.join}</ul>"),
      '</li>',
    ].join
  end
end

template = "#{source}/page.gtx"
gtx = GTX.load_file(template)
layout = ERB.new(File.read("#{source}/layout.html.erb"))

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
all_commands.each do |cmd|
  slug = command_slug(cmd)
  markdown = gtx.parse(cmd)
  content = Kramdown::Document.new(markdown).to_html

  breadcrumbs = cmd.parents + [cmd.name]
  breadcrumb_html = breadcrumbs.map.with_index do |name, index|
    if index.zero?
      "<a href=\"index.html\">#{command.name}</a>"
    else
      name
    end
  end.join(' / ')

  nav_html = "<ul>#{nav_items(command, slug).join}</ul>"
  page_title = cmd.full_name
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
