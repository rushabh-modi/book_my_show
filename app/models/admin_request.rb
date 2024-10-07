class AdminRequest < ApplicationRecord
  after_update :handle_status_change, if: -> { status_previously_changed? }

  validates :contact_email, :contact_no, :admin_emails, :theater_name, :theater_address, :pincode, :business_license,
            :ownership_proof, :noc, :insurance, :status, presence: true
  validates :contact_email, uniqueness: { message: 'was already used once to fill this form.' },
                            format: { with: /\A[-a-z0-9_+.]+@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i, message: 'is in invalid format' }
  validates :admin_emails,
            format: {
              with: /\A[-a-z0-9_+.]+@([-a-z0-9]+\.)+[a-z0-9]{2,4}(\s*,\s*[-a-z0-9_+.]+@([-a-z0-9]+\.)+[a-z0-9]{2,4})*\z/i, message: 'must be in valid format with comma between them'
            }
  validates :theater_address, length: { in: 1..240, message: 'must be between 1 to 240 letters' }
  validates :contact_no, uniqueness: true, length: { is: 10 }
  validates :pincode, length: { is: 6 }

  validate :theater_name_already_exists, on: :create

  enum status: %i[pending approved rejected]

  has_one_attached :business_license
  has_one_attached :ownership_proof
  has_one_attached :noc
  has_one_attached :insurance

  validates :business_license, :ownership_proof, :noc, :insurance,
            attached: true,
            content_type: { in: %w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document], message: 'must be in valid format of .pdf, .docx, .doc' },
            size: { between: 1.kilobyte..5.megabytes, message: 'should be less than 5 MB' }

  private

  def handle_status_change
    if approved?
      activate_theater_and_admins
      AdminMailer.admin_request_approved(contact_email).deliver_later
    elsif rejected?
      destroy_resources
      AdminMailer.admin_request_rejected(contact_email).deliver_later
    end
  end

  def activate_theater_and_admins
    # OPTIMIZE: wrap in transaction
    theater = Theater.find_by(name: theater_name)
    theater&.update!(status: :active)

    admin_emails.split(',').map(&:strip).each do |email|
      user = User.find_by(email:)
      user&.update!(status: :active)
      user&.send_admin_invitation_email
    end
  end

  # TODO: change method name
  def destroy_resources
    # OPTIMIZE: wrap in transaction
    theater = Theater.find_by(name: theater_name)
    theater&.destroy!

    admin_emails.split(',').map(&:strip).each do |email|
      user = User.find_by(email:)
      user&.destroy!
    end
  end

  def theater_name_already_exists
    errors.add(:theater_name, 'with this name already exists') if Theater.find_by(name: theater_name).present?
  end

  # TODO: remove this
  def admin_emails_already_exists
    admin_emails.split(',').map(&:strip).each do |email|
      errors.add(:admin_emails, "#{email} is already a registered user") if User.find_by(email:).present?
    end
  end
end
