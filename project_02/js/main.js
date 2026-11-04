$(function () {
    const $win = $(window);
    const $doc = $(document);
    const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])';

    /* ================= 준비 중(미구현) 안내 ================= */
    const $toast = $('<div class="toast" role="status" aria-live="polite"></div>').appendTo('body');
    let toastTimer;
    function showToast(msg) {
        clearTimeout(toastTimer);
        $toast.text(msg).addClass('show');
        toastTimer = setTimeout(function () { $toast.removeClass('show'); }, 2500);
    }
    $doc.on('click', '.pending', function (e) {
        e.preventDefault();
        showToast('준비 중인 기능입니다. 이 사이트는 학습용으로 메인과 인사말 페이지만 구현했습니다.');
    });

    /* ================= 메인 비주얼 자동 슬라이드 + 일시정지 ================= */
    const $slides = $('.slide');
    const $pauseBtn = $('.slide_pause');
    let slideTimer = null;
    function nextSlide() {
        $('.slide:first').fadeOut(2000).next().fadeIn(2000);
        $('.slide:first').appendTo('.slide-wrap');
    }
    function playSlide() {
        if (slideTimer || $slides.length < 2) return;
        slideTimer = setInterval(nextSlide, 4000);
        $pauseBtn.attr({ 'aria-pressed': 'false', 'aria-label': '자동 슬라이드 일시정지' })
            .find('i').attr('class', 'fa-solid fa-pause');
    }
    function pauseSlide() {
        clearInterval(slideTimer);
        slideTimer = null;
        $pauseBtn.attr({ 'aria-pressed': 'true', 'aria-label': '자동 슬라이드 재생' })
            .find('i').attr('class', 'fa-solid fa-play');
    }
    if ($slides.length) {
        $('.slide:gt(0)').hide();
        // 움직임 줄이기 설정을 사용하는 경우 자동 재생하지 않음
        const reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (reduceMotion) { pauseSlide(); } else { playSlide(); }
        $pauseBtn.on('click', function () {
            if (slideTimer) { pauseSlide(); } else { playSlide(); }
        });
    }

    /* ================= hover 이미지 전환 (조사절차 · 바로가기) ================= */
    function swapIcon(on) {
        const $img = $(this).find('img');
        const src = $img.attr('src');
        if (src) $img.attr('src', on ? src.replace('_off', '_on') : src.replace('_on', '_off'));
    }
    $('.progress .progress_box, .banner_metapo .metapo .metapo_box')
        .on('mouseenter', function () { swapIcon.call(this, true); })
        .on('mouseleave', function () { swapIcon.call(this, false); });

    /* ================= 스크롤 고정 헤더 · TOP 버튼 ================= */
    $win.on('scroll', function () {
        if ($(this).scrollTop() >= 200) {
            $('.header_outer').addClass('fixed');
            $('.btn_top').fadeIn(500);
        } else {
            $('.header_outer').removeClass('fixed');
            $('.btn_top').fadeOut(500);
        }
    });
    $('.btn_top a').on('click', function (e) {
        e.preventDefault();
        $win.scrollTo(0, 500);
        $('#content').attr('tabindex', '-1').trigger('focus');
    });

    /* ================= 탭 공통 (공지·언론보도, 모바일 메뉴 분류) =================
       role="tablist" 안의 role="tab" 버튼과 aria-controls로 연결된 패널을 전환
       좌우(가로) / 상하(세로) 방향키, Home, End 지원 */
    function selectTab($tab, focus) {
        const $list = $tab.closest('[role="tablist"]');
        const $tabs = $list.find('[role="tab"]');
        $tabs.each(function () {
            const selected = this === $tab[0];
            $(this).toggleClass('on', selected)
                .attr({ 'aria-selected': String(selected), tabindex: selected ? '0' : '-1' });
            const $panel = $('#' + $(this).attr('aria-controls'));
            $panel.prop('hidden', !selected).toggleClass('on_sheet', selected);
        });
        if (focus) $tab.trigger('focus');
    }
    $doc.on('click', '[role="tab"]', function () { selectTab($(this), false); });
    $doc.on('keydown', '[role="tab"]', function (e) {
        const $tabs = $(this).closest('[role="tablist"]').find('[role="tab"]');
        const vertical = $(this).closest('[role="tablist"]').attr('aria-orientation') === 'vertical';
        const i = $tabs.index(this);
        let next = null;
        if (e.key === (vertical ? 'ArrowDown' : 'ArrowRight')) next = (i + 1) % $tabs.length;
        else if (e.key === (vertical ? 'ArrowUp' : 'ArrowLeft')) next = (i - 1 + $tabs.length) % $tabs.length;
        else if (e.key === 'Home') next = 0;
        else if (e.key === 'End') next = $tabs.length - 1;
        if (next === null) return;
        e.preventDefault();
        selectTab($tabs.eq(next), true);
    });

    /* ================= 현장공개 썸네일 ================= */
    $('.open_img_btn button').on('click', function () {
        const index = $(this).data('index');
        $('.open_img_btn').removeClass('on').find('button').attr('aria-pressed', 'false');
        $(this).attr('aria-pressed', 'true').parent().addClass('on');
        $('.sheet').removeClass('on').hide().eq(index).addClass('on').fadeIn(300);
    });

    /* ================= PC 메뉴 (hover + 키보드) ================= */
    const $gnbPc = $('.gnb_pc');
    const $gnbBtns = $gnbPc.find('.gnb_pc_btn');
    let gnbCloseTimer;
    function setGnb(open) {
        clearTimeout(gnbCloseTimer);
        $gnbPc.toggleClass('is_open', open);
        $gnbBtns.attr('aria-expanded', String(open));
    }
    $gnbPc
        .on('mouseenter', function () { setGnb(true); })
        .on('mouseleave', function () {
            // 포커스가 메뉴 안에 있으면 닫지 않음, 짧은 지연으로 실수로 벗어나도 바로 닫히지 않게 함
            gnbCloseTimer = setTimeout(function () {
                if (!$gnbPc[0].contains(document.activeElement)) setGnb(false);
            }, 200);
        })
        .on('focusout', function () {
            setTimeout(function () {
                if (!$gnbPc[0].contains(document.activeElement) && !$gnbPc.is(':hover')) setGnb(false);
            }, 0);
        })
        .on('keydown', function (e) {
            if (e.key === 'Escape' && $gnbPc.hasClass('is_open')) {
                const $item = $(e.target).closest('.gnb_pc_item');
                setGnb(false);
                $item.find('.gnb_pc_btn').trigger('focus');
            }
        });
    $gnbBtns
        .on('click', function () { setGnb($(this).attr('aria-expanded') !== 'true'); })
        .on('keydown', function (e) {
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                setGnb(true);
                // 이동 가능한(구현된) 첫 하위 링크로 초점 이동
                const $first = $(this).next('.gnb_pc_sub').find('a[href]').first();
                setTimeout(function () { $first.trigger('focus'); }, 0);
            }
        });

    /* ================= 모바일 · 태블릿 전체 메뉴 ================= */
    const $mobile = $('.gnb_mobile');
    const $toggle = $mobile.find('.gnb_m_toggle');
    const $box = $('#gnb_mobile_box');
    const $header = $('.header_outer');
    const $outside = $('body').children().not('.header_outer, .toast, script').add($header.find('.header > .logo'));

    function openMobileMenu() {
        $box.prop('hidden', false);
        $header.addClass('menu_open');
        $toggle.attr({ 'aria-expanded': 'true', 'aria-label': '전체 메뉴 닫기' })
            .find('i').attr('class', 'fa-solid fa-xmark');
        $outside.attr('inert', '').attr('aria-hidden', 'true');
        $('body').css('overflow', 'hidden');
        $box.find('[role="tab"][aria-selected="true"]').trigger('focus');
    }
    function closeMobileMenu(returnFocus) {
        if ($box.prop('hidden')) return;
        $box.prop('hidden', true);
        $header.removeClass('menu_open');
        $toggle.attr({ 'aria-expanded': 'false', 'aria-label': '전체 메뉴 열기' })
            .find('i').attr('class', 'fa-solid fa-bars');
        $outside.removeAttr('inert aria-hidden');
        $('body').css('overflow', '');
        if (returnFocus) $toggle.trigger('focus');
    }
    $toggle.on('click', function () {
        if ($box.prop('hidden')) { openMobileMenu(); } else { closeMobileMenu(true); }
    });
    // 메뉴 안 링크(앵커 포함)를 누르면 메뉴 닫기
    $box.on('click', 'a[href]', function () { closeMobileMenu(false); });
    // Escape로 닫기, Tab 초점이 열린 메뉴 밖으로 빠지지 않도록 순환
    $doc.on('keydown', function (e) {
        if ($box.prop('hidden')) return;
        if (e.key === 'Escape') { closeMobileMenu(true); return; }
        if (e.key !== 'Tab') return;
        const $f = $mobile.find(FOCUSABLE).filter(':visible').not('[tabindex="-1"]');
        if (!$f.length) return;
        const first = $f[0], last = $f[$f.length - 1];
        if (e.shiftKey && (document.activeElement === first || !$mobile[0].contains(document.activeElement))) {
            e.preventDefault(); last.focus();
        } else if (!e.shiftKey && (document.activeElement === last || !$mobile[0].contains(document.activeElement))) {
            e.preventDefault(); first.focus();
        }
    });
    // 태블릿 메뉴 바깥(어두운 영역) 클릭 시 닫기
    $doc.on('click', function (e) {
        if (!$box.prop('hidden') && !$(e.target).closest('.gnb_mobile, .toast').length) closeMobileMenu(true);
    });
    // PC 폭으로 바뀌면 모바일 메뉴 닫기
    $win.on('resize', function () {
        if (window.innerWidth >= 1025) closeMobileMenu(false);
    });
});
