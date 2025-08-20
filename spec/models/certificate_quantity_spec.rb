require 'rails_helper'

describe CertificateQuantity, type: :model do
  it do
    is_expected.to define_enum_for(:status).with_values(active: "active", intransit: "intransit", retired: "retired")
                                           .backed_by_column_of_type(:string)
  end
end
