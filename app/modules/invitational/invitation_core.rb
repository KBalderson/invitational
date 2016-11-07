module Invitational
  module InvitationCore
    extend ActiveSupport::Concern

    included do
      belongs_to :invitable, :polymorphic => true

      before_create :setup_hash

      validates :email,  :presence => true
      validates :role,  :presence => true
      validates :invitable,  :presence => true, :if => :standard_role?

      scope :uberadmin, lambda {
        where(invitable_id: nil, role: :uberadmin)
      }

      scope :for_email, lambda {|email|
        where(email: email)
      }

      scope :pending_for, lambda {|email|
        where(email: email, user_id: nil)
      }

      scope :for_claim_hash, lambda {|claim_hash|
        where(claim_hash: claim_hash)
      }

      scope :for_invitable, lambda {|type, id|
        where(invitable_type: type, invitable_id: id)
      }

      scope :by_role, lambda {|role|
        where(role: role.to_s)
      }

      scope :for_system_role, lambda {|role|
        where(invitable_id: nil, role: role.to_s)
      }

      scope :pending, lambda { where(user_id: nil) }
      scope :claimed, lambda { where.not(user_id: nil) }

      @system_roles = [:uberadmin]

      def self.system_roles
        @system_roles
      end
    end

    module ClassMethods
      def claim claim_hash, user
        Invitational::ClaimsInvitation.for claim_hash, user
      end

      def claim_all_for user
        Invitational::ClaimsAllInvitations.for user
      end

      def invite_uberadmin target
        Invitational::CreatesUberAdminInvitation.for target
      end

      def invite_system_user target, role
        Invitational::CreatesSystemUserInvitation.for target, role
      end

      def accepts_system_roles_as *args
        args.each do |role|
          relation = role.to_s.pluralize.to_sym

          scope relation, -> {where(invitable_id: nil, role: role.to_s)}

          self.system_roles << role
        end
      end

    end

    def setup_hash
      self.date_sent = DateTime.now
      self.claim_hash = Digest::SHA1.hexdigest(email + date_sent.to_s)
    end

    def standard_role?
      roles = Invitation.system_roles + [:uberadmin]
      !roles.include?(role)
    end

    def role
      unless super.nil?
        super.to_sym
      end
    end

    def role=(value)
      super(value.to_sym)
      role
    end

    def role_title
      if uberadmin?
        "Uber Admin"
      else
        role.to_s.titleize
      end
    end

    def uberadmin?
      invitable.nil? == true && role == :uberadmin
    end

    def claimed?
      date_accepted.nil? == false
    end

    def unclaimed?
      !claimed?
    end
  end
end
