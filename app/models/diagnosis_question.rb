class DiagnosisQuestion < ApplicationRecord
  validates :content, presence: true
  validates :position, presence: true
end
