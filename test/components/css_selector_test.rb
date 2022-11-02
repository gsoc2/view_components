# frozen_string_literal: true

require "components/test_helper"

class CssSelectorTest < Minitest::Test
  include Primer::ComponentTestHelpers

  def test_selectors_match
    css = JSON.parse(File.read("app/components/primer/beta/button.css.json"))
    require_relative "../../previews/primer/beta/button_preview"

    previews = [:default, :primary, :link]
    matched_selectors = []

    previews.each do |preview|
      preview_page = render_preview(preview, preview_klass: Primer::Beta::ButtonPreview)

      css["selectors"].each do |selector|
        result = preview_page.css(selector)
        matched_selectors << selector unless result.empty?
      end
    end

    puts css["selectors"] - matched_selectors
  end

  private

  def render_preview(name, preview_klass: nil, params: {})
    if preview_klass.nil?
      begin
        preview_klass = if respond_to?(:described_class)
          raise "`render_preview` expected a described_class, but it is nil." if described_class.nil?

          "#{described_class}Preview"
        else
          self.class.name.gsub("Test", "Preview")
        end
        preview_klass = preview_klass.constantize
      rescue NameError
        raise NameError, "`render_preview` expected to find #{preview_klass}, but it does not exist."
      end
    end

    previews_controller = build_controller(Rails.application.config.view_component.preview_controller.constantize)

    # From what I can tell, it's not possible to overwrite all request parameters
    # at once, so we set them individually here.
    params.each do |k, v|
      previews_controller.request.params[k] = v
    end

    previews_controller.request.params[:path] = "#{preview_klass.preview_name}/#{name}"
    previews_controller.response = ActionDispatch::Response.new
    result = previews_controller.previews

    @rendered_content = result

    Nokogiri::HTML.fragment(@rendered_content)
  end
end
