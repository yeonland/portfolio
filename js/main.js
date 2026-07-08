$(function () {
    // 원페이지 스크롤
    // 1. GNB 클릭 시 이동
    $('.header .gnb a').click(function(e){
        e.preventDefault();
        $(window).scrollTo(this.hash || 0, 500);
    });

    // 2. 통합 휠 이벤트 (충돌 방지 및 반응형 처리)
    $(window).on('mousewheel DOMMouseScroll', function(e) {
        // 작은 화면에서는 휠 강제 이동 기능 X
        if ($(window).width() <= 1200) return;

        let delta = e.originalEvent.wheelDelta || -e.originalEvent.detail;
        let $currentSection = $(e.target).closest('section');
        
        // 휠을 굴릴 때 현재 섹션이 없으면 첫 섹션으로 간주
        if ($currentSection.length === 0) $currentSection = $('#page01');

        e.preventDefault();
        if (delta > 0) { // 위로
            let prev = $currentSection.prev('section').offset()?.top;
            if (prev !== undefined) $('html, body').stop().animate({scrollTop: prev}, 1000);
        } else { // 아래로
            let next = $currentSection.next('section').offset()?.top;
            if (next !== undefined) $('html, body').stop().animate({scrollTop: next}, 1000);
        }
    });

    // 3. 스크롤 시 메뉴 색상 자동 변경 (별도의 독립적 함수)
    $(window).on('scroll', function () {
        const scrollTop = $(window).scrollTop();
        const $gnbLinks = $('.gnb li a');
        
        // 인트로 범위 내 초기화
        if (scrollTop < $('#page02').offset().top - 100) {
            $gnbLinks.each(function () {
                const img = $(this).find('img');
                img.attr('src', img.attr('src').replace('-on', '-off'));
                $(this).find('span').css('color', '#999');
            });
            return;
        }

        // 각 섹션별 색상 변경
        ['#page02', '#page03', '#page04', '#page05'].forEach((id, index) => {
            const $section = $(id);
            if ($section.length === 0) return;
            const top = $section.offset().top - 100;
            const bottom = top + $section.outerHeight();

            if (scrollTop >= top && scrollTop < bottom) {
                $gnbLinks.each(function () {
                    const img = $(this).find('img');
                    img.attr('src', img.attr('src').replace('-on', '-off'));
                    $(this).find('span').css('color', '#999');
                });
                const $current = $gnbLinks.eq(index);
                $current.find('img').attr('src', $current.find('img').attr('src').replace('-off', '-on'));
                $current.find('span').css('color', '#F4E53B');
            }
        });
    });

    $('.open_img_btn').click(function() {
        // 1. 클릭한 버튼의 인덱스 가져오기
        let index = $(this).data('index');

        // 2. 모든 sheet 숨기고, 선택한 인덱스만 fade 효과로 보여주기
        $('.sheet').hide().eq(index).fadeIn(500);

        // 3. 버튼 활성화 상태 표시 (선택사항)
        $('.open_img_btn').removeClass('on');
        $(this).addClass('on');
    });

    // 탭 전환 기능
    $('.tab-button').click(function() {
        const targetTab = $(this).data('tab')
        
        // 모든 탭 버튼에서 active 클래스 제거
        $('.tab-button').removeClass('active')
        
        // 클릭된 탭 버튼에 active 클래스 추가
        $(this).addClass('active')
        
        // 모든 탭 콘텐츠에서 active 클래스 제거
        $('.tab-content').removeClass('active')
        
        // 해당 탭에 active 클래스 추가
        $('#' + targetTab).addClass('active')
    });

    // 모달
    // 모달 열기
    $('.show-modal-btn').on('click', function(e) {
        e.preventDefault();
        
        const imgSrc = $(this).data('img'); // 이미지 소스 가져오기
        const title = $(this).data('title'); // 제목 가져오기

        // 이미지 및 제목을 모달에 설정
        $('#modal img').attr('src', imgSrc);
        $('.modal-title').text(title);  // 제목을 모달에 삽입

        // 모달 열기
        $('#modal').fadeIn();
    });

    // 모달 닫기
    $('.close').on('click', function() {
        $('#modal').fadeOut();  // 모달 닫기
    });
    // 배경 클릭 시 닫기
    $('#modal').on('click', function(e) {
        if ($(e.target).is('#modal')) {
            $('#modal').fadeOut();
        }
    });
})