$(function() {
    // 1. 장바구니 영역: 아이콘과 팝업 박스를 하나의 그룹처럼 묶어서 이벤트 적용
    $('.header_outer .header .gnb_icon .btn_cart, .cart_box').on('mouseenter', function(){
        $('.cart_box').stop().slideDown(300);
    }).on('mouseleave', function(){
        $('.cart_box').stop().slideUp(300);
    });

    // 2. 최근 본 상품 영역: 아이콘과 팝업 박스를 하나의 그룹처럼 묶어서 이벤트 적용
    $('.header_outer .header .gnb_icon .btn_recent, .recent_box').on('mouseenter', function(){
        $('.recent_box').stop().slideDown(300);
    }).on('mouseleave', function(){
        $('.recent_box').stop().slideUp(300);
    });

    // 3. TOP 버튼 부드럽게 스크롤
    $('.btn_top').click(function(){
       $(window).scrollTo(this.hash || 0, 600)
    });
});