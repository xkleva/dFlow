class PdfHelper
  # Generates a work order pdf for job
  def self.create_work_order job
    md_value = 8

    pdf = Prawn::Document.new :page_size=> 'A4', :margin=>[10.send(:mm), 10.send(:mm), 12.7.send(:mm), 10.send(:mm)]

    pdf.move_down 2.7.send(:mm)

    pdf.text "#{job.id}", :size=>24, :style=>:bold

    pdf.bounding_box([0, pdf.cursor], :width => (110).send(:mm)) do
      pdf.text "#{job.treenode.breadcrumb_as_string}", :size=>12
    end

    pdf.font_size = 12

    pdf.move_down 2.7.send(:mm)

    pdf.bounding_box([0, pdf.cursor], :width => (110).send(:mm), :height => (250).send(:mm)) do

      if job.name.present?
        pdf.text "Namn", :style=>:bold
        pdf.text "#{job.name} "
        pdf.move_down md_value
      end

      pdf.text "Titel", :style=>:bold
      pdf.text "#{job.display} "
      pdf.move_down md_value

      pdf.text "Författare", :style=>:bold
      pdf.text "#{job.author} "
      pdf.move_down md_value

      pdf.text "Källa", :style=>:bold
      pdf.text "#{job.source_label} (ID: #{job.catalog_id} )"
      pdf.move_down md_value

      pdf.text "Objektinformaton", :style=>:bold
      pdf.text "#{job.object_info} "
      pdf.move_down md_value

      pdf.text "Kommentar", :style=>:bold
      pdf.text "#{job.comment} "
      pdf.move_down md_value

      #pdf.transparent(0.5) { pdf.stroke_bounds}
    end

    pdf.bounding_box([325,780], :width => 215, :height => 740) do
      pdf.stroke_bounds
      pdf.bounding_box([20,720], :width => 190) do

        pdf.font_size = 10
        pdf.text "Status", :style=>:bold
        pdf.move_down md_value
        pdf.text "[ ] Påbörjad   2 0 _ _ - _ _ - _ _"
        pdf.move_down md_value
        pdf.text "[ ] Skannad    2 0 _ _ - _ _ - _ _"
        pdf.move_down md_value*2

        pdf.text "Operatör", :style=>:bold
        pdf.move_down md_value
        unless APP_CONFIG["pdf_settings"]["operators"].blank?
          pdf.text APP_CONFIG["pdf_settings"]["operators"]
          pdf.move_down md_value
          pdf.text "[ ] Annan: __________________"
        else
          pdf.text "________________________"
        end

        pdf.move_down md_value*2

        pdf.text "Utrustning", :style=>:bold
        pdf.move_down md_value
        unless APP_CONFIG["pdf_settings"]["equipments"].blank?
          pdf.text APP_CONFIG["pdf_settings"]["equipments"]
          pdf.move_down md_value
          pdf.text "[ ] Annan: __________________"
        else
          pdf.text "________________________"
        end
        pdf.move_down md_value*2

        pdf.text "Svårighetsgrad", :style => :bold
        pdf.move_down md_value
        pdf.text "[ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ]"
        pdf.move_down md_value*2

        pdf.text "Tidsåtgång", :style => :bold
        pdf.move_down md_value
        pdf.text "Skanning ink kvalitetskontr: ________ min"
        pdf.move_down md_value
        pdf.text "Efterbearbetning:                 ________ min"
        pdf.move_down md_value*2
        pdf.text "Kommentarer", :style=>:bold
        #pdf.text "#{job.comment} "
        pdf.move_down md_value
      end

      #pdf.transparent(0.5) { pdf.stroke_bounds}
    end


    pdf.move_cursor_to (7).send(:mm)
    pdf.line [0, pdf.cursor], [pdf.bounds.right, pdf.cursor]
    pdf.stroke

    pdf.move_cursor_to (5).send(:mm)

    pdf.text "DFlow - #{Date.today.strftime("%F")}", :size => 10
    pdf.draw_text "Göteborgs Universitetsbibliotek", {:at=>[pdf.bounds.right - 140, 8], :size=>10}

    pdf.render
  end

end