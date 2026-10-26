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

            // 작업물 창이 열려 있으면 창 안에서 기본 스크롤 사용
            if (!$('#designModal').prop('hidden')) return;

            // 가로 휠(트랙패드 좌우 밀기)은 프로젝트 카드 넘기기에 사용
            if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) return;

            // 스크롤 애니메이션 중이면 추가 실행 방지
            if (isScrolling) {
                e.preventDefault();
                return;
            }

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

            // 화면보다 긴 섹션은 끝까지 본 뒤에 다음 섹션으로 넘김 (창 높이가 낮을 때 아래 내용이 잘리지 않게)
            const $current = $sections.eq(currentIndex);
            const currentTop = $current.offset().top;
            const currentBottom = currentTop + $current.outerHeight();
            if (direction > 0 && currentBottom > scrollTop + window.innerHeight + 1) return;
            if (direction < 0 && scrollTop > currentTop + 1) return;

            // PC에서는 브라우저의 기본 스크롤 방지
            e.preventDefault();
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
        // [섹션, 메뉴 순서] — 프로젝트 섹션 두 개는 같은 '프로젝트' 메뉴를 켬
        [['#page02', 0], ['#page03', 1], ['#page04', 2], ['#page04-2', 2], ['#design', 3], ['#page05', 4]].forEach(([id, index]) => {
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

    // 진행 중인 프로젝트 좌우 넘기기
    const $track = $('#page04-2 .cards-container');
    const $prev = $('#page04-2 .slider-btn.prev');
    const $next = $('#page04-2 .slider-btn.next');
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function updateSliderButtons() {
        const track = $track[0];
        $prev.prop('disabled', track.scrollLeft <= 1);
        $next.prop('disabled', track.scrollLeft + track.clientWidth >= track.scrollWidth - 1);
    }

    $('#page04-2 .slider-btn').on('click', function () {
        const step = $track.find('.card').outerWidth() + parseFloat($track.css('column-gap'));
        $track[0].scrollBy({
            left: $(this).hasClass('next') ? step : -step,
            behavior: reduceMotion ? 'auto' : 'smooth'
        });
    });

    $track.on('scroll', updateSliderButtons);
    $(window).on('resize', updateSliderButtons);
    updateSliderButtons();

    // 3. 디자인 작업물 크게 보기
    const mockups = [];
    for (let row = 1; row <= 3; row++) {
        for (let col = 1; col <= 4; col++) {
            mockups.push({ src: `./project_01/img/07_${row}_${col} metapo.jpg`, alt: `소하 상품 목업 ${mockups.length + 1}` });
        }
    }

    const galleries = {
        'soha-visual': {
            title: '소하 · 브랜드 비주얼',
            groups: [
                { name: '브랜드·상품 배너', items: [{ src: './img/design/soha-banner.jpg', alt: '소하 브랜드 소개 배너와 상품 배너' }] },
                { name: '메인 비주얼', items: [1, 2, 3, 4, 5, 6].map((n) => ({ src: `./project_01/img/02_main_visual0${n}.jpg`, alt: `소하 메인 비주얼 ${n}` })) },
                { name: '상품 목업', grid: true, items: mockups }
            ]
        },
        'soha-product': {
            title: '소하 · 상품 디자인',
            groups: [{ name: '디지털 속지', items: [{ src: './img/product.jpg', alt: '일주일 플래너, 습관 트래커, 위클리 속지' }] }]
        },
        'simda': {
            title: '심다 · 저축 습관 앱 UI',
            groups: [
                { name: '앱 화면', items: [{ src: './img/design/simda-app.jpg', alt: '심다 앱 화면 흐름' }] },
                { name: '스타일 가이드', items: [{ src: './img/style_guide.jpg', alt: '심다 타이포그래피, 컬러, 버튼 스타일 가이드' }] }
            ]
        },
        'graphic': {
            title: '개인 그래픽 작업',
            groups: [
                { name: '2026 롯데자이언츠 캘린더', items: [{ src: './img/design/calendar.jpg', alt: '롯데자이언츠 팀 컬러로 만든 야구 없는 날 캘린더' }] },
                { name: '미니 가계부', grid: true, items: [
                    { src: './img/design/budget.jpg', alt: '미니 가계부' },
                    { src: './img/design/budget-black.jpg', alt: '미니 가계부 블랙' }
                ] }
            ]
        }
    };

    const $modal = $('#designModal');
    const $modalBody = $modal.find('.design-modal-body');
    let $lastTrigger = null;

    function openGallery(key, $trigger) {
        const gallery = galleries[key];
        if (!gallery) return;

        $modal.find('#designModalTitle').text(gallery.title);
        $modalBody.empty();

        gallery.groups.forEach((group) => {
            $('<h4>').text(group.name).appendTo($modalBody);
            const $wrap = $('<div>').addClass(group.grid ? 'design-modal-grid' : 'design-modal-list').appendTo($modalBody);
            group.items.forEach((item) => {
                $('<img>', { src: item.src, alt: item.alt, loading: 'lazy' }).appendTo($wrap);
            });
        });

        $lastTrigger = $trigger;
        $modal.prop('hidden', false);
        $('body').addClass('modal-open');
        $modalBody.scrollTop(0);
        $modal.find('.design-modal-close').trigger('focus');
    }

    function closeGallery() {
        $modal.prop('hidden', true);
        $('body').removeClass('modal-open');
        if ($lastTrigger) $lastTrigger.trigger('focus');
    }

    $('.design-open, .design-thumb').on('click', function () {
        openGallery($(this).data('gallery'), $(this).closest('.design-card').find('.design-open'));
    });

    $modal.find('.design-modal-close').on('click', closeGallery);

    // 바깥 어두운 영역을 누르면 닫기
    $modal.on('click', function (e) {
        if (e.target === this) closeGallery();
    });

    $(document).on('keydown', function (e) {
        if (e.key === 'Escape' && !$modal.prop('hidden')) closeGallery();
    });
})