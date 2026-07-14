$(function() {
    // 1. 장바구니 
    $('.btn_cart, .cart_box').on('mouseenter', function(){
        $('.cart_box').stop().slideDown(300);
    }).on('mouseleave', function(){
        $('.cart_box').stop().slideUp(300);
    });

    // 2. 최근 본 상품 
    $('.btn_recent, .recent_box').on('mouseenter', function(){
        $('.recent_box').stop().slideDown(300);
    }).on('mouseleave', function(){
        $('.recent_box').stop().slideUp(300);
    });

    // 3. TOP 버튼 부드럽게 스크롤
    $('.btn_top').click(function(){
       $(window).scrollTo(this.hash || 0, 600)
    });
    
    // 사용법 닫기
    $('.how_use_close').on('click', function () {
        $('.how_use_wrap').fadeOut(300);
    });
});