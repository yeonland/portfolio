$(function () {
    // 1. 스크롤 이벤트
    let isScrolling = false;
    const speed = 600;

    // GNB / 로고 클릭 시 이동
    $('header .gnb a, .logo a').on('click', function (e) {
        e.preventDefault();

        const target = $(this).attr('href');

        $('html, body').stop(true, false);

        // 첫 페이지는 무조건 맨 위로 이동
        if (target === '#page01') {
            $.scrollTo(0, speed);
        } else {
            $.scrollTo(target, speed);
        }
    });

    function headerShowHide() {
        const scrollTop = $(window).scrollTop();
        const page02Top = $('#page02').offset().top;

        if (scrollTop >= page02Top - 100) {
            $('header').removeClass('header-hidden').addClass('header-visible');
        } else {
            $('header').removeClass('header-visible').addClass('header-hidden');
        }
        }

        $(window).on('scroll resize', function () {
        headerShowHide();
    });

    headerShowHide();

    // 마우스 휠 원페이지 스크롤
    $(window).on('mousewheel', function (e) {
        const isMobileOrTablet =
            window.innerWidth <= 1024 ||
            window.matchMedia('(pointer: coarse)').matches;

        // 모바일·태블릿 - 기본 스크롤
        if (isMobileOrTablet) return;

        /*
        휠 이벤트는 한 번 굴려도 여러 번 발생,
        isScrolling 확인보다 기본 스크롤을 막기
        */
        e.preventDefault();

        if (isScrolling) return;

        const $sections = $('section');
        const scrollTop = $(window).scrollTop();

        let currentIndex = 0;

        $sections.each(function (index) {
            const sectionTop = $(this).offset().top;

            if (scrollTop >= sectionTop - 100) {
                currentIndex = index;
            }
        });

        const direction = e.deltaY < 0 ? 1 : -1;
        const nextIndex = currentIndex + direction;

        // 첫 페이지 위 / 마지막 페이지 아래 = 실행 X 
        if (nextIndex < 0 || nextIndex >= $sections.length) {
            return;
        }

        const $target = $sections.eq(nextIndex);
        const destination = nextIndex === 0 ? 0 : $target;

        isScrolling = true;

        // 기존에 진행 중인 스크롤 애니메이션 제거
        $('html, body').stop(true, false);

        $.scrollTo(destination, speed, {
            axis: 'y',

            // 실제 애니메이션이 끝난 다음 잠금 해제
            onAfter: function () {
                isScrolling = false;
            }
        });
});

    // 2. 스크롤 시 메뉴 색상 자동 변경
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
})