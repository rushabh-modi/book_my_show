ActiveAdmin.register Show do
  remove_filter :poster_attachment, :poster_blob, :cpics_attachments, :cpics_blobs

  show do
    attributes_table do
      row :name
      row :description
      row :poster do |p|
        if p.poster.attached?
          image_tag url_for(p.poster)
        end
      end
      row :cast
      row :language
      row :genre
      row :category
      row :status
      row :duration
      row :release_date
    end
  end

  form decorate: true do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :poster, as: :file
      f.input :cast, label: "Cast: (add comma between entries)"
      f.input :language
      f.input :genre
      f.input :category
      f.input :status
      f.input :duration, label: 'Duration of show (in Minutes)'
      f.input :release_date
      unless f.object.new_record?
        f.input :slug, label: "name helper for url"
      end
    end
    f.actions
  end

  permit_params :name, :description, :poster, :cast, :language, :genre, :category, :status, :duration, :release_date,:slug
end
