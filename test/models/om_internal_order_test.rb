require "test_helper"

class OmInternalOrderTest < ActiveSupport::TestCase
  test "auto-generates ord_no on create" do
    order = OmInternalOrder.create!(
      ord_stat_cd: "WAIT",
      wait_ord_internal_yn: "N",
      cancel_yn: "N"
    )

    assert order.ord_no.present?
    assert_match(/\AIO\d{8}\d{6}\z/, order.ord_no)
  end

  test "generates sequential ord_no" do
    order1 = OmInternalOrder.create!(ord_stat_cd: "WAIT", wait_ord_internal_yn: "N", cancel_yn: "N")
    order2 = OmInternalOrder.create!(ord_stat_cd: "WAIT", wait_ord_internal_yn: "N", cancel_yn: "N")

    seq1 = order1.ord_no[-6..].to_i
    seq2 = order2.ord_no[-6..].to_i
    assert_equal seq1 + 1, seq2
  end

  test "limits items to 20" do
    order = OmInternalOrder.new(ord_stat_cd: "WAIT", wait_ord_internal_yn: "N", cancel_yn: "N")
    21.times do |i|
      order.items.build(seq_no: i + 1, item_cd: "ITEM#{i}")
    end

    assert_not order.valid?
    assert order.errors[:items].any?
  end

  test "cancel! sets cancel_yn and ord_stat_cd" do
    order = OmInternalOrder.create!(ord_stat_cd: "WAIT", wait_ord_internal_yn: "N", cancel_yn: "N")
    order.cancel!

    assert_equal "Y", order.cancel_yn
    assert_equal "CANCEL", order.ord_stat_cd
  end

  test "default scope filters by wait_ord_internal_yn N" do
    internal = OmInternalOrder.create!(ord_stat_cd: "WAIT", wait_ord_internal_yn: "N", cancel_yn: "N")
    external = OmInternalOrder.unscoped.create!(
      ord_no: "EXT#{Time.current.strftime('%Y%m%d')}000001",
      ord_stat_cd: "WAIT",
      wait_ord_internal_yn: "Y",
      cancel_yn: "N"
    )

    assert_includes OmInternalOrder.all, internal
    assert_not_includes OmInternalOrder.all, external
  end

  test "creates order with items" do
    order = OmInternalOrder.create!(
      ord_stat_cd: "WAIT",
      wait_ord_internal_yn: "N",
      cancel_yn: "N",
      items_attributes: [
        { seq_no: 1, item_cd: "ITEM001", item_nm: "테스트아이템", ord_qty: 10 },
        { seq_no: 2, item_cd: "ITEM002", item_nm: "테스트아이템2", ord_qty: 5 }
      ]
    )

    assert_equal 2, order.items.count
  end
end
