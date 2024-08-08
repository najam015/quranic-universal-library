# frozen_string_literal: true

# == Schema Information
#
# Table name: feedbacks
#
#  id         :bigint           not null, primary key
#  email      :string
#  message    :text
#  name       :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
ActiveAdmin.register Feedback do
  menu parent: 'Notes'
  actions :index, :show
end
