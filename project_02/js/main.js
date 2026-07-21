$(function() {
    $('.slide:gt(0)').hide()
    setInterval(function(){
        $('.slide:first').fadeOut(2000).next().fadeIn(2000)
        $('.slide:first').appendTo('.slide-wrap')
    }, 4000)

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
            $('.header_outer').addClass('fixed')
            $('.btn_top').fadeIn(500)
        } else {
            $('.header_outer').removeClass('fixed')
            $('.btn_top').fadeOut(500)
        }
    })    // scroll_event
    $('.btn_top').click(function(){
        $(window).scrollTo(this.hash || 0, 500)
    }) // btn_top_event
    
    // 현장공개
    $('.open_img_btn').click(function() {
        // 1. 클릭한 버튼의 인덱스 가져오기
        let index = $(this).data('index');
        
        // 2. 버튼 활성화 상태 표시
        $('.open_img_btn').removeClass('on');
        $(this).addClass('on');

        // 3. 모든 sheet 숨기기 + 선택한 인덱스만 fade 효과로 보여주기
        $('.sheet').removeClass('on').hide().eq(index).addClass('on').fadeIn(300);
    });
    // 공지사항 탭
    const $noticeTab = $('.notice_news_tab .tab');
    const $noticeSheet = $('.notice_news_sheet .tab_sheet');

    $noticeTab.on('click', function () {
        const index = $noticeTab.index(this);

        $noticeTab
            .removeClass('on')
            .attr('aria-selected', 'false');

        $(this)
            .addClass('on')
            .attr('aria-selected', 'true');

        $noticeSheet
            .removeClass('on_sheet')
            .eq(index)
            .addClass('on_sheet');
    });
})    // jqueary

