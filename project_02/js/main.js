$(function() {
    $('.slide:gt(0)').hide()
    setInterval(function(){
        $('.slide:first').fadeOut(1500).next().fadeIn(1500)
        $('.slide:first').appendTo('.slide-wrap')
    }, 3000)

    // mouseEvent_img_change_event_progress
    const imgChange = $('.progress .progress_box')
    imgChange.hover (function() {
            $(this).find('img').attr('src', $(this).find('img').attr('src').replace('_off', '_on'))
        }, function() {
            $(this).find('img').attr('src', $(this).find('img').attr('src').replace('_on', '_off'))
        }
    )      
    
    // mouse_img_change_event_metapo
    const imgSwitch = $('.banner_metapo .metapo .metapo_box')
    imgSwitch.hover (function() {
        $(this).find('img').attr('src', $(this).find('img').attr('src').replace('_off', '_on'))
    }, function() {
        $(this).find('img').attr('src', $(this).find('img').attr('src').replace('_on', '_off'))
    })      
    
    $(window).scroll(function() {
        if ($(this).scrollTop() >=200) {
            $('.header').addClass('fixed')
            $('.btn_top').fadeIn(500)
        } else {
            $('header').removeClass('fixed')
            $('.btn_top').fadeOut(500)
        }
    })    // scroll_event
    $('.btn_top').click(function(){
       $(window).scrollTo(this.hash || 0, 500)
    }) // btn_top_event

    const imgBtn=$('.open ul li')
    const imgSheet=$('.open .open_img_sheet .open_img')

    tab.click(function(){
        index=$(this).index()

        imgBtn.removeClass('on')
        imgBtn.eq(index).addClass('on')

        imgSheet.removeClass('on_sheet')
        imgSheet.eq(index).addClass('on_sheet')
    })
    // 현장공개
    $('.open_img_btn').click(function() {
        // 1. 클릭한 버튼의 인덱스 가져오기
        let index = $(this).data('index');

        // 2. 모든 sheet 숨기고, 선택한 인덱스만 fade 효과로 보여주기
        $('.sheet').hide().eq(index).fadeIn(500);

        // 3. 버튼 활성화 상태 표시 (선택사항)
        $('.open_img_btn').removeClass('active');
        $(this).addClass('active');
    });
    const tab=$('.notice_news ul li')
    const sheet=$('.notice_news .notice_news_sheet div')

    tab.click(function(){
        index=$(this).index()

        tab.removeClass('on')
        tab.eq(index).addClass('on')

        sheet.removeClass('on_sheet')
        sheet.eq(index).addClass('on_sheet')
    })
    $('.center').slick({
        centerMode: true,
        centerPadding: '60px',
        slidesToShow: 3,
        responsive: [
        {
            breakpoint: 768,
            settings: {
            arrows: false,
            centerMode: true,
            centerPadding: '40px',
            slidesToShow: 3
            }
        },
        {
            breakpoint: 480,
            settings: {
            arrows: false,
            centerMode: true,
            centerPadding: '40px',
            slidesToShow: 1
            }
        }
        ]
    });
})    // jqueary

