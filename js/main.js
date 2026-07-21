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
    window.addEventListener(
        'wheel',
        function (e) {
            const isMobileOrTablet =
                window.innerWidth <= 1024 ||
                window.matchMedia('(pointer: coarse)').matches;

            // 모바일·태블릿에서는 기본 스크롤 사용
            if (isMobileOrTablet) return;

            // PC에서는 브라우저의 기본 스크롤 방지
            e.preventDefault();

            // 스크롤 애니메이션 중이면 추가 실행 방지
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

            // 네이티브 wheel 이벤트:
            // deltaY가 양수면 아래, 음수면 위
            const direction = e.deltaY > 0 ? 1 : -1;
            const nextIndex = currentIndex + direction;

            // 첫 섹션 위 또는 마지막 섹션 아래에서는 이동하지 않음
            if (nextIndex < 0 || nextIndex >= $sections.length) {
                return;
            }

            const $target = $sections.eq(nextIndex);
            const destination =
                nextIndex === 0 ? 0 : $target.offset().top;

            isScrolling = true;

            // 진행 중인 스크롤 애니메이션 중단
            $('html, body').stop(true, false);

            $.scrollTo(destination, speed, {
                axis: 'y',

                onAfter: function () {
                    isScrolling = false;
                }
            });
        },
        { passive: false }
    );

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