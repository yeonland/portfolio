$(function () {
    // 1. 스크롤 이벤트
    let isScrolling = false;
    const speed = 800;

    // GNB / 로고 클릭 시 이동
    $('header .gnb a, .logo a').on('click', function (e) {
        e.preventDefault();

        const target = $(this).attr('href');

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
            $('header').removeClass('hidden').addClass('visible');
        } else {
            $('header').removeClass('visible').addClass('hidden');
        }
        }

        $(window).on('scroll resize', function () {
        headerShowHide();
    });

    headerShowHide();

    // 마우스 휠 원페이지 스크롤
    $(window).on('mousewheel', function (e) {
        if ($(window).width() <= 1200) return;
        if (isScrolling) return;

        e.preventDefault();
        isScrolling = true;

        const scrollTop = $(window).scrollTop();
        let currentIndex = 0;

        $('section').each(function (index) {
            const sectionTop = $(this).offset().top;

            if (scrollTop >= sectionTop - 100) {
                currentIndex = index;
            }
        });

        if (e.deltaY < 0) {
            // 아래로 스크롤
            currentIndex++;
        } else {
            // 위로 스크롤
            currentIndex--;
        }

        const $target = $('section').eq(currentIndex);

        if ($target.length) {
        if ($target.attr('id') === 'page01') {
            $.scrollTo(0, speed);
        } else {
            $.scrollTo($target, speed);
        }
        }

        setTimeout(function () {
            isScrolling = false;
        }, speed + 100);
    });

    // 2. 스크롤 시 메뉴 색상 자동 변경 (별도의 독립적 함수)
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