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

    // 검색 창 뜨기
    $('.search_toggle').on('click', function () {
        $('.search_box').toggleClass('on');

        if ($('.search_box').hasClass('on')) {
            $(this).html('<i class="fa-solid fa-xmark"></i>');
            $(this).attr('aria-label', '검색창 닫기');
            $('.search_txt').focus();
        } else {
            $(this).html('<i class="fa-solid fa-magnifying-glass"></i>');
            $(this).attr('aria-label', '검색창 열기');
        }
    });

    // FAQ 하나만 뜨기
    $('.faq_box details').on('toggle', function () {
        if (this.open) {
            $('.faq_box details').not(this).removeAttr('open');
        }
    });
});