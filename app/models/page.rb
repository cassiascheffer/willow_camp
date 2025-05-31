class Page < Post
  belongs_to :author, class_name: "User"
end
