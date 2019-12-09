class UserStep < ApplicationRecord
  belongs_to :step
  belongs_to :user_journey

  has_many :user_tasks, dependent: :destroy

  scope :completed, -> { where(status: 'done') }
  scope :recently_active, -> do
    joins('LEFT JOIN user_tasks on user_tasks.user_step_id = user_steps.id')
      .where('user_steps.updated_at > ? or user_tasks.updated_at > ?', 1.month.ago, 1.month.ago)
      .where('user_steps.status != ? and user_steps.status != ?', 'done', 'not_started')
  end

  validates :status, inclusion: { in: %w(not_started started waiting done) }

  def refresh_status
    if all_tasks_completed? && !step.has_app?
      update(status: 'done')
    elsif user_tasks.completed.none?
      update(status: 'not_started')
    else
      update(status: 'started')
    end
  end

  def done?
    status == 'done'
  end

  def waiting?
    status == 'waiting'
  end

  def all_tasks_completed?
    step.tasks.count == user_tasks.completed.count
  end
end
