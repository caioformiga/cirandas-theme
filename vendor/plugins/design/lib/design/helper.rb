module Design

  module Helper

    # proxies calls to controller's design method to get the design information
    # holder object
    def design
      @controller.send(:design)
    end

    ########################################################
    # Boxes and Blocks related
    ########################################################

    # Displays +content+ inside the design used by the controller. Normally
    # you'll want use this method in your layout view, like this:
    #
    #   <%= design_display(yield) %>
    #
    # +content+ will be put inside all the blocks which return +true+ in the
    # Block.main? method.
    #
    # The number of boxes generated will be no larger than the maximum number
    # supported by the template, which is indicated in its YAML description
    # file.
    #
    # If not blocks are present (e.g. the design holder has no blocks yet),
    # +content+ is returned right away.
    #
    # If running in design_editor mode
    def design_display(content = "")

      # dispatch to Design::Editor::Helper if running in editor mode
      if (self.respond_to?(:design_display_editor) && params[:action] =~ /^design_editor/)
        return design_display_editor(content) 
      end

      # no blocks. nothing to be done
      if design.boxes.empty?
        return content 
      end

      # Generate all boxes of the current profile and considering the defined
      # on template.

      design.boxes.map do |box|
        content_tag(:div, design_display_blocks(box, content) , :id=>"box_#{box.number}")
      end.join("\n") + "\n"
    end

    # Displays all the blocks in a box.
    #   <ul id="sort#{number of the box}">
    #     <li class="block_item_box_#{number of the box}" id="block_#{id of block}">
    #     </li>
    #   </ul>
    #
    def design_display_blocks(box, content = "")
      blocks = box.blocks_sort_by_position
      blocks.map do |block|
        # FIXME: should that actually be list_content?
        text = block.main? ? content : design_block_content(block)
        content_tag(:div, text, :class => "block" , :id => "block_#{block.id}" )
      end.join("\n")+ "\n"
    end

    # Displays the content of a block. See plugin README for details about the
    # possibilities.
    def design_block_content(block)
      content = block.content
      case content
      when Proc
        self.instance_eval(&content)
      when Array
        content_tag(
          'ul',
          content.map do |c|
            content_tag(
            'li',
            c
            )
          end
        )
      else
        content.to_s
      end
    end

    ####################################
    # TEMPLATES
    ####################################

    # Generates <script> tags for all existing javascript files of the current
    # design template.
    #
    # The javascript files must be named as *.js and must be under
    # #{RAILS_ROOT}/public/#{Design.design_root}/templates/#{templatename}/javascripts.
    def design_template_javascript_include_tags
      pattern = File.join(Design.public_filesystem_root, Design.design_root, 'templates', design.template, 'javascripts', '*.js')
      javascript_files = Dir.glob(pattern)

      return '' if javascript_files.empty?

      javascript_files.map do |filename|
        javascript_include_tag('/' + File.join(Design.design_root, 'templates', design.template, 'javascripts', File.basename(filename)))
      end.join("\n") + "\n"
    end

    # Generates links to all the CSS files provided by the template being used.
    #
    # The CSS files must be named as *.css and live in the directory
    # #{RAILS_ROOT}/public/#{Design.design_root}/templates/#{templatename}/stylesheets/
    def design_template_stylesheet_link_tags

      pattern = File.join(Design.public_filesystem_root, Design.design_root, 'templates', design.template, 'stylesheets', '*.css')
      stylesheet_files = Dir.glob(pattern)

      return '' if stylesheet_files.empty?

      stylesheet_files.map do |filename|
        stylesheet_link_tag('/' + File.join(Design.design_root, 'templates', design.template, 'stylesheets', File.basename(filename)))
      end.join("\n") + "\n"
    end


    #################################################
    #THEMES 
    #################################################

    # generates links for all existing theme CSS files in the current design.
    #
    # The CSS files must be named as *.css and live in the directory
    # #{RAILS_ROOT}/public/#{Design.design_root}/themes/{theme_name}/
    def design_theme_stylesheet_link_tags
      pattern = File.join(Design.public_filesystem_root, Design.design_root, 'themes', design.theme, '*.css')
      stylesheet_files = Dir.glob(pattern)

      return '' if stylesheet_files.empty?

      stylesheet_files.map do |filename|
        stylesheet_link_tag('/' + File.join(Design.design_root, 'themes', design.theme, File.basename(filename)))
      end.join("\n") + "\n"

    end

    ###############################################
    # ICON THEME STUFF
    ###############################################

    # displays the icon given named after the +icon+ argument, using the
    # current icon_theme.
    #
    # There must be a file named +icon+.png in the directory 
    # #{RAILS_ROOT}/public/designs/icons/#{icon_theme}
    # 
    # Ths optional +options+ argument is passed untouched to the image_tag
    # Rails helper
    def design_display_icon(icon, options = {})
      filename = (icon =~ /\.png$/) ? icon : (icon + '.png')
      image_tag('/' + File.join(Design.design_root, 'icons', design.icon_theme, filename), options) + "\n"
    end

    ###############################################
    # GENERAL UTILITIES
    ###############################################

    # generates all header tags needed to use the design. The same as calling +design_template_javascript_include_tags+, +design_template_stylesheet_link_tags+ and 'design_theme_stylesheet_link_tags
    def design_all_header_tags
      design_template_javascript_include_tags + 
      design_template_stylesheet_link_tags +
      design_theme_stylesheet_link_tags
    end

  end # END OF module Helper

end #END OF module Design
